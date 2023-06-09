import Atomics
import Combine
import Foundation
import MapKit
import SwiftUI

class CasesViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let dataPullReporter: IncidentDataPullReporter
    private let mapCaseIconProvider: MapCaseIconProvider
    private let logger: AppLogger

    @Published private(set) var incidentsData = LoadingIncidentsData

    @Published private(set) var showDataProgress = false
    @Published private(set) var dataProgress = 0.0

    private let qsm: CasesQueryStateManager

    private let mapBoundsManager: CasesMapBoundsManager

    @Published private(set) var incidentLocationBounds = MapViewCameraBoundsDefault

    @Published private(set) var isMapBusy: Bool = false
    private let isGeneratingWorksiteMarkers = CurrentValueSubject<Bool, Never>(false)
    private let isDelayingRegionBug = CurrentValueSubject<Bool, Never>(false)

    private let mapMarkerManager: CasesMapMarkerManager

    private let mapMarkersLock = NSLock()
    @Published private(set) var incidentMapMarkers: IncidentAnnotations = emptyIncidentAnnotations
    private let wipeIncidentAnnotations = ManagedAtomic(false)

    @Published private(set) var casesCount: (Int, Int) = (-1, -1)

    private var hasDisappeared = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentBoundsProvider: IncidentBoundsProvider,
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        dataPullReporter: IncidentDataPullReporter,
        mapCaseIconProvider: MapCaseIconProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentSelector = incidentSelector
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.dataPullReporter = dataPullReporter
        self.mapCaseIconProvider = mapCaseIconProvider

        logger = loggerFactory.getLogger("cases")

        mapBoundsManager = CasesMapBoundsManager(
            incidentSelector,
            incidentBoundsProvider
        )

        mapMarkerManager = CasesMapMarkerManager(worksitesRepository: worksitesRepository)

        qsm = CasesQueryStateManager(incidentSelector)
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeIncidentsData()
        subscribeIncidentBounds()
        subscribeWorksiteInBounds()
        subscribeDataPullStats()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
        hasDisappeared = true
    }

    private func subscribeLoading() {
        Publishers.CombineLatest4(
            incidentsRepository.isLoading.eraseToAnyPublisher(),
            mapBoundsManager.isDeterminingBoundsPublisher.eraseToAnyPublisher(),
            isGeneratingWorksiteMarkers,
            isDelayingRegionBug
        )
            .receive(on: RunLoop.main)
            .sink { b0, b1, b2, b3 in
                self.isMapBusy = b0 || b1 || b2 || b3
            }
            .store(in: &subscriptions)
    }

    private func subscribeIncidentsData() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeIncidentBounds() {
        mapBoundsManager.mapCameraBoundsPublisher
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { bounds in
                if self.hasDisappeared {
                    self.hasDisappeared = false
                } else {
                    self.incidentLocationBounds = bounds
                }
            })
            .store(in: &subscriptions)
    }

    private func subscribeWorksiteInBounds() {
        let worksitesInBounds = qsm.worksiteQueryState
            .eraseToAnyPublisher()
            .debounce(
                for: .seconds(0.25),
                scheduler: RunLoop.main
            )
            .asyncThrowsMap { wqs in
                let queryIncidentId = wqs.incidentId

                if queryIncidentId != self.incidentMapMarkers.incidentId {
                    Task { @MainActor in
                        self.casesCount = (-1, -1)
                        self.resetMapMarkers()
                    }
                    throw CancellationError()
                }

                var annotations = [WorksiteAnnotationMapMark]()
                if queryIncidentId != EmptyIncident.id {
                    Task { @MainActor in self.isGeneratingWorksiteMarkers.value = true }
                    do {
                        defer {
                            Task { @MainActor in self.isGeneratingWorksiteMarkers.value = false }
                        }

                        annotations = try await self.generateWorksiteMarkers(wqs)
                    } catch {
                        self.logger.logError(error)
                    }
                }

                return (queryIncidentId, annotations)
            }

        worksitesInBounds.asyncThrowsMap { (queryIncidentId, annotations) in
            var idSet: Set<Int64>? = nil

            if self.wipeIncidentAnnotations.exchange(false, ordering: .sequentiallyConsistent) {
                idSet = []
            } else {
                self.mapMarkersLock.withLock {
                    let incidentAnnotations = self.incidentMapMarkers
                    if queryIncidentId == self.incidentsData.selectedId {
                        idSet = incidentAnnotations.annotationIdSet
                    }
                }
            }

            var incidentAnnotations = IncidentAnnotations(EmptyIncident.id)
            if var annotationIds = idSet {
                var newAnnotations: [WorksiteAnnotationMapMark] = []
                for mark in annotations {
                    let worksiteId = mark.source.id
                    if !annotationIds.contains(worksiteId) {
                        annotationIds.insert(worksiteId)
                        newAnnotations.append(mark)
                    }
                }
                incidentAnnotations = IncidentAnnotations(
                    queryIncidentId,
                    annotationIdSet: annotationIds,
                    newAnnotations: newAnnotations
                )
            } else {
                throw CancellationError()
            }
            return incidentAnnotations
        }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { incidentAnnotations in
                if incidentAnnotations.incidentId == self.incidentsData.selectedId {
                    self.mapMarkersLock.withLock {
                        self.incidentMapMarkers = incidentAnnotations
                    }
                }
            })
            .store(in: &subscriptions)

        let incidentWorksitesCount = incidentSelector.incidentId
            .eraseToAnyPublisher()
            .map { id in
                self.worksitesRepository.streamIncidentWorksitesCount(id)
                    .eraseToAnyPublisher()
                    .map { count in (id, count) }
            }
            .switchToLatest()
            .map { (id, count) in IncidentIdWorksiteCount(id: id, count: count) }

        self.incidentsRepository.isLoading.eraseToAnyPublisher()
            .combineLatest(
                worksitesInBounds.eraseToAnyPublisher(),
                incidentWorksitesCount.eraseToAnyPublisher()
            )
            .map { (isSyncing, inBoundsMarkers, worksitesCount) in
                var totalCount = worksitesCount.count
                if totalCount == 0 && isSyncing {
                    totalCount = -1
                }
                return (inBoundsMarkers.1.count, totalCount)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.casesCount, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeDataPullStats() {
        dataPullReporter.incidentDataPullStats
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { stats in
                self.showDataProgress = stats.isOngoing
                self.dataProgress = stats.progress
            }
            .store(in: &subscriptions)
    }

    @MainActor
    private func resetMapMarkers() {
        mapMarkersLock.withLock {
            incidentMapMarkers = IncidentAnnotations(incidentsData.selectedId)
        }
    }

    // TODO: Redesign the annotation generation stream to be certain so view does not need to report when markers are missing
    func onMissingMapMarkers() {
        logger.logDebug("!Missing annotations")
        _ = wipeIncidentAnnotations.exchange(true, ordering: .acquiring)
    }

    private let zeroOffset = (0.0, 0.0)

    private func generateWorksiteMarkers(_ wqs: WorksiteQueryState) async throws -> [WorksiteAnnotationMapMark] {
        let id = wqs.incidentId
        let sw = wqs.coordinateBounds.southWest
        let ne = wqs.coordinateBounds.northEast
        let marksQuery = try await mapMarkerManager.queryWorksitesInBounds(id, sw, ne)
        let marks = marksQuery.0
        let markOffsets = try denseMarkerOffsets(marks)

        try Task.checkCancellation()

        return marks.enumerated().map { (index, mark) in
            let offset = index < markOffsets.count ? markOffsets[index] : zeroOffset
            return mark.asAnnotationMapMark(mapCaseIconProvider, offset)
        }
    }

    func onMapCameraChange(
        _ zoom: Double,
        _ region: MKCoordinateRegion,
        _ didAnimate: Bool
    ) {
        qsm.mapZoomSubject.value = zoom

        let center = region.center
        let span = region.span
        qsm.mapBoundsSubject.value = CoordinateBounds(
            southWest: center.subtract(span).latLng,
            northEast: center.add(span).latLng
        )

        // Seems like there is a map view bug. This accounts for those times.
        if !didAnimate {
            isDelayingRegionBug.value = true
            Task {
                do {
                    defer {
                        Task { @MainActor in self.isDelayingRegionBug.value = false }
                    }
                    // TODO: This fails when the number of worksites is large and the delay expires before all data is downloaded.
                    //       Better to get to the bottom of the bug than compounding the hack.
                    // Animations seem to take around half a second - 1 second. Split the diff.
                    try await Task.sleep(for: .seconds(0.7))
                    self.qsm.mapZoomSubject.value = self.qsm.mapZoomSubject.value + Double.random(in: -0.001..<0.001)
                } catch {
                    self.logger.logDebug(error.localizedDescription)
                }
            }
        }
    }

    private let denseMarkCountThreshold = 15
    private let denseMarkZoomThreshold = 14.0
    private let denseDegreeThreshold = 0.0001
    private let denseScreenOffsetScale = 0.6
    private func denseMarkerOffsets(_ marks: [WorksiteMapMark]) throws -> [(Double, Double)] {
        if marks.count > denseMarkCountThreshold ||
            qsm.mapZoomSubject.value < denseMarkZoomThreshold
        {
            return []
        }

        try Task.checkCancellation()

        var bucketIndices = Array(repeating: -1, count: marks.count)
        var buckets = [[Int]]()
        for i in 0 ..< max(0, marks.count - 1) {
            let iMark = marks[i]
            for j in i + 1 ..< max(1, marks.count) {
                let jMark = marks[j]
                if abs(iMark.latitude - jMark.latitude) < denseDegreeThreshold &&
                    abs(iMark.longitude - jMark.longitude) < denseDegreeThreshold
                {
                    let bucketI = bucketIndices[i]
                    if bucketI >= 0 {
                        bucketIndices[j] = bucketI
                        buckets[bucketI].append(j)
                    } else {
                        let bucketJ = bucketIndices[j]
                        if bucketJ >= 0 {
                            bucketIndices[i] = bucketJ
                            buckets[bucketJ].append(i)
                        } else {
                            let bucketIndex = buckets.count
                            bucketIndices[i] = bucketIndex
                            bucketIndices[j] = bucketIndex
                            buckets.append([i, j])
                        }
                    }
                    break
                }
            }

            try Task.checkCancellation()
        }

        var markOffsets = marks.map { _ in zeroOffset }
        if buckets.isNotEmpty {
            buckets.forEach {
                let count = Double($0.count)
                let offsetScale = denseScreenOffsetScale + max(count - 5.0, 0.0) * 0.2
                if count > 1.0 {
                    var offsetDir = .pi * 0.5
                    let deltaDirDegrees = 2.0 * .pi / count
                    $0.enumerated().forEach { (index, _) in
                        markOffsets[index] = (
                            offsetScale * cos(offsetDir),
                            offsetScale * sin(offsetDir)
                        )
                        offsetDir += deltaDirDegrees
                    }
                }
            }
        }
        return markOffsets
    }
}

extension CLLocationCoordinate2D {
    var latLng: LatLng { LatLng(latitude, longitude) }

    func add(_ span: MKCoordinateSpan) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude + span.latitudeDelta,
            longitude: longitude + span.longitudeDelta
        )
    }

    func subtract(_ span: MKCoordinateSpan) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude - span.latitudeDelta,
            longitude: longitude - span.longitudeDelta
        )
    }
}

struct IncidentIdWorksiteCount {
    let id: Int64
    let count: Int
}

struct IncidentAnnotations {
    let incidentId: Int64
    var annotationIdSet: Set<Int64>
    let newAnnotations: [WorksiteAnnotationMapMark]

    init(
        _ incidentId: Int64,
        annotationIdSet: Set<Int64> = Set<Int64>(),
        newAnnotations: [WorksiteAnnotationMapMark] = [WorksiteAnnotationMapMark]()
    ) {
        self.incidentId = incidentId
        self.annotationIdSet = annotationIdSet
        self.newAnnotations = newAnnotations
    }
}

private let emptyIncidentAnnotations = IncidentAnnotations(EmptyIncident.id)
