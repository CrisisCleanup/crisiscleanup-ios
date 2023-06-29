import SwiftUI
import Combine
import Foundation

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

    @Published private(set) var worksiteMapMarkers: [WorksiteIconMapMark] = []

    private var disposables = Set<AnyCancellable>()
    private var observableSubscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentBoundsProvider: IncidentBoundsProvider,
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
                    return [WorksiteIconMapMark]()
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
                return [WorksiteIconMapMark]()
            }
            .map({ marks in
                print("Marks \(marks.count)")
                return marks
            })
            .receive(on: RunLoop.main)
            .assign(to: \.worksiteMapMarkers, on: self)
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

    private func generateWorksiteMarkers(_ wqs: WorksiteQueryState) async throws -> [WorksiteIconMapMark] {
        let id = wqs.incidentId
        let sw = wqs.coordinateBounds.southWest
        let ne = wqs.coordinateBounds.northEast
        let marksQuery = try await mapMarkerManager.queryWorksitesInBounds(id, sw, ne)
        let marks = marksQuery.0
        let markOffsets = try denseMarkerOffsets(marks)

        try Task.checkCancellation()

        return marks.enumerated().map { (index, mark) in
            let offset = index < markOffsets.count ? markOffsets[index] : zeroOffset
            return mark.asWorksiteIconMapMark(mapCaseIconProvider, offset)
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
        for i in 0 ..< marks.count - 1 {
            let iMark = marks[i]
            for j in i + 1 ..< marks.count {
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
