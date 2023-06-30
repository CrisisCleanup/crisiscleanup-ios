import SwiftUI
import Combine
import Foundation
import MapKit

class CasesViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
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
    private lazy var incidentLocationBoundsPublisher = $incidentLocationBounds

    @Published private(set) var isMapBusy: Bool = false
    private let isGeneratingWorksiteMarkers = CurrentValueSubject<Bool, Never>(false)

    private let mapMarkerManager: CasesMapMarkerManager

    @Published private(set) var worksiteMapMarkers: [WorksiteAnnotationMapMark] = []
    private lazy var mapMarkersPublisher = $worksiteMapMarkers

    @Published private(set) var casesCount: (Int, Int) = (0, 0)

    private var disposables = Set<AnyCancellable>()
    private var observableSubscriptions = Set<AnyCancellable>()

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

        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { self.incidentsData = $0 }
            .store(in: &disposables)

        mapBoundsManager.mapCameraBoundsPublisher
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: &incidentLocationBoundsPublisher)

        mapBoundsManager.isDeterminingBoundsPublisher
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { b0 in
                self.isMapBusy = b0
            }
            .store(in: &disposables)

        qsm.worksiteQueryState
            .eraseToAnyPublisher()
            .debounce(
                for: .seconds(0.25),
                scheduler: RunLoop.main
            )
            .asyncMap { wqs in
                if wqs.incidentId == EmptyIncident.id {
                    return [WorksiteAnnotationMapMark]()
                } else {
                    Task { @MainActor in self.isGeneratingWorksiteMarkers.value = true }
                    do {
                        defer {
                            Task { @MainActor in self.isGeneratingWorksiteMarkers.value = false }
                        }

                        return try await self.generateWorksiteMarkers(wqs)
                    } catch {
                        self.logger.logError(error)
                    }
                }
                return [WorksiteAnnotationMapMark]()
            }
            .map({ marks in
                print("Marks \(marks.count)")
                return marks
            })
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.worksiteMapMarkers, on: self)
            .store(in: &disposables)

        let incidentWorksitesCount = incidentSelector.incidentId
            .eraseToAnyPublisher()
            .map { id in
                worksitesRepository.streamIncidentWorksitesCount(id)
                    .eraseToAnyPublisher()
                    .map { count in (id, count) }
            }
            .switchToLatest()
            .map { (id, count) in IncidentIdWorksiteCount(id: id, count: count) }

        incidentsRepository.isLoading.eraseToAnyPublisher()
            .combineLatest(
                mapMarkersPublisher.eraseToAnyPublisher(),
                incidentWorksitesCount.eraseToAnyPublisher()
            )
            .map { (isSyncing, markers, worksitesCount) in
                var totalCount = worksitesCount.count
                if (totalCount == 0 && isSyncing) {
                    totalCount = -1
                }
                return (markers.count, totalCount)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.casesCount, on: self)
            .store(in: &disposables)
    }

    func onViewAppear() {
        // TODO: Subscribe to other subscriptions that are only relevent on screen
        subscribeDataPullStats()
    }

    func onViewDisappear() {
        let subscriptions = observableSubscriptions
        observableSubscriptions = Set<AnyCancellable>()
        for subscription in subscriptions {
            subscription.cancel()
        }
    }

    private func subscribeDataPullStats() {
        dataPullReporter.incidentDataPullStats
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { stats in
                self.showDataProgress = stats.isOngoing
                self.dataProgress = stats.progress
            }
            .store(in: &observableSubscriptions)
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
        _ region: MKCoordinateRegion
    ) {
        qsm.mapZoomSubject.value = zoom

        let center = region.center
        let span = region.span
        qsm.mapBoundsSubject.value = CoordinateBounds(
            southWest: center.subtract(span).latLng,
            northEast: center.add(span).latLng
        )
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
