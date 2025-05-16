import Atomics
import Combine
import CombineExt
import Foundation
import MapKit
import SwiftUI

class CasesViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let appPreferences: AppPreferencesDataSource
    private let dataPullReporter: IncidentDataPullReporter
    private let worksiteLocationEditor: WorksiteLocationEditor
    private let mapCaseIconProvider: MapCaseIconProvider
    private let worksiteInteractor: WorksiteInteractor
    private let locationManager: LocationManager
    private let worksiteProvider: WorksiteProvider
    private let transferWorkTypeProvider: TransferWorkTypeProvider
    private let filterRepository: CasesFilterRepository
    let phoneNumberParser: PhoneNumberParser
    private let translator: KeyTranslator
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    @Published private(set) var incidentsData = LoadingIncidentsData
    private let incidentWorksitesCount: AnyPublisher<IncidentIdWorksiteCount, Never>
    var selectedIncident: Incident { incidentsData.selected }
    var incidentId: Int64 { incidentsData.selectedId }

    private let incidentIdPublisher: AnyPublisher<Int64, Never>

    @Published private(set) var dataProgress = DataProgressMetrics()

    @Published private(set) var isLoadingIncidents = true
    @Published private(set) var isLoadingData = false

    private let qsm: CasesQueryStateManager

    @Published var editedWorksiteLocation: CLLocationCoordinate2D?

    @Published private(set) var filtersCount = 0

    @Published private(set) var isTableView = false

    private let tableDataDistanceSortSearchRadius = 100.0

    @Published var tableViewSort = WorksiteSortBy.none
    private let pendingTableSort = ManagedAtomic(AtomicSortBy())
    private let tableSortResultsMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var tableSortResultsMessage = ""

    private let tableViewDataLoader: CasesTableViewDataLoader
    @Published var isLoadingTableViewData: Bool = false

    let openWorksiteAddFlagCounter = CurrentValueSubject<Int, Never>(0)
    private let openWorksiteAddFlag = ManagedAtomic(false)

    @Published var worksitesChangingClaimAction: Set<Int64> = []
    private let changeClaimActionErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published var changeClaimActionErrorMessage = ""

    private let mapBoundsManager: CasesMapBoundsManager

    @Published private(set) var mapCameraBounds = MapViewCameraBoundsDefault
    @Published private(set) var incidentMapBounds = MapViewCameraBoundsDefault

    @Published private(set) var isMapBusy: Bool = false
    private let isGeneratingWorksiteMarkers = CurrentValueSubject<Bool, Never>(false)
    private let isDelayingRegionBug = CurrentValueSubject<Bool, Never>(false)

    private let mapCaseDotProvider = InMemoryDotProvider()
    @Published private(set) var mapDotsOverlay: CasesMapDotsOverlay
    @Published private(set) var debugOverlay: MKTileOverlay?
    private let mapMarkerManager: CasesMapMarkerManager
    internal var mapView: MKMapView?

    private let epochZero = Date(timeIntervalSince1970: 0)
    private let tileClearRefreshInterval = 5.seconds
    private var tileRefreshedTimestamp = Date(timeIntervalSince1970: 0)

    private let mapMarkersChangeSetSubject = CurrentValueSubject<AnnotationsChangeSet, Never>(emptyAnnotationsChangeSet)
    @Published private(set) var mapMarkersChangeSet = emptyAnnotationsChangeSet
    private let mapAnnotationsExchanger: MapAnnotationsExchanger

    @Published var tableData = [WorksiteDistance]()
    @Published private(set) var isTableEditable = false

    @Published private(set) var casesCountTableText = ""
    @Published private(set) var casesCountMapText = ""
    @Published private(set) var hasCasesCountProgress = false

    private var hasDisappeared = false
    private var incidentOnDisappear = EmptyIncident.id

    @Published var showExplainLocationPermission = false
    @Published private(set) var isMyLocationEnabled = false

    private let latestBoundedMarkersPublisher = LatestAsyncThrowsPublisher<IncidentAnnotations>()
    private let latestMapMarkersPublisher = LatestAsyncThrowsPublisher<AnnotationsChangeSet>()
    private let latestTableDataPublisher = LatestAsyncPublisher<[WorksiteDistance]>()

    private var onZoomIncidentTimestamp = Date.distantPast

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentBoundsProvider: IncidentBoundsProvider,
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        accountDataRepository: AccountDataRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        organizationsRepository: OrganizationsRepository,
        appPreferences: AppPreferencesDataSource,
        dataPullReporter: IncidentDataPullReporter,
        worksiteLocationEditor: WorksiteLocationEditor,
        mapCaseIconProvider: MapCaseIconProvider,
        worksiteInteractor: WorksiteInteractor,
        locationManager: LocationManager,
        worksiteProvider: WorksiteProvider,
        transferWorkTypeProvider: TransferWorkTypeProvider,
        filterRepository: CasesFilterRepository,
        phoneNumberParser: PhoneNumberParser,
        translator: KeyTranslator,
        syncPuller: SyncPuller,
        loggerFactory: AppLoggerFactory,
        appEnv: AppEnv
    ) {
        self.incidentSelector = incidentSelector
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.appPreferences = appPreferences
        self.dataPullReporter = dataPullReporter
        self.worksiteLocationEditor = worksiteLocationEditor
        self.mapCaseIconProvider = mapCaseIconProvider
        self.worksiteInteractor = worksiteInteractor
        self.locationManager = locationManager
        self.worksiteProvider = worksiteProvider
        self.transferWorkTypeProvider = transferWorkTypeProvider
        self.filterRepository = filterRepository
        self.phoneNumberParser = phoneNumberParser
        self.translator = translator
        self.syncPuller = syncPuller
        logger = loggerFactory.getLogger("cases")

        incidentIdPublisher = incidentSelector.incidentId
            .eraseToAnyPublisher()
            .removeDuplicates()
            .replay1()

        incidentWorksitesCount = worksitesRepository.streamIncidentWorksitesCount(incidentIdPublisher)
            .eraseToAnyPublisher()
            .replay1()

        tableViewDataLoader = CasesTableViewDataLoader(
            worksiteProvider: worksiteProvider,
            worksitesRepository: worksitesRepository,
            worksiteChangeRepository: worksiteChangeRepository,
            accountDataRepository: accountDataRepository,
            organizationsRepository: organizationsRepository,
            incidentsRepository: incidentsRepository,
            translator: translator,
            logger: logger
        )

        mapBoundsManager = CasesMapBoundsManager(
            incidentSelector,
            incidentBoundsProvider,
            appPreferences
        )

        mapMarkerManager = CasesMapMarkerManager(
            worksitesRepository: worksitesRepository,
            locationManager: locationManager
        )

        let queryStateManager = CasesQueryStateManager(
            incidentSelector,
            filterRepository
        )
        qsm = queryStateManager

        mapAnnotationsExchanger = MapAnnotationsExchanger(mapMarkersChangeSetSubject)

        mapDotsOverlay = CasesMapDotsOverlay(
            worksitesRepository: worksitesRepository,
            mapCaseDotProvider: mapCaseDotProvider,
            filterRepository: filterRepository
        )
        if appEnv.isDebuggable {
            debugOverlay = TileCoordinateOverlay()
        }
    }

    deinit {
        mapBoundsManager.unsubscribe()
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeIncidentsData()
        subscribeCameraBounds()
        subscribeWorksiteInBounds()
        subscribeDataPullStats()
        subscribeViewState()
        subscribeSortBy()
        subscribeTableData()
        subscribeLocationStatus()
        subscribeFilterCount()
        subscribeMapTiles()

        if let location = worksiteLocationEditor.takeEditedLocation() {
            editedWorksiteLocation = location
        }
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
        hasDisappeared = true
        incidentOnDisappear = incidentId
    }

    private func subscribeLoading() {
        let incidentsLoading = incidentsRepository.isLoading
            .eraseToAnyPublisher()
            .replay1()

        incidentsLoading
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidents, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            incidentsLoading,
            $dataProgress,
            worksitesRepository.isDeterminingWorksitesCount.eraseToAnyPublisher()
        )
        .map { b0, progress, b2 in b0 || progress.isLoadingPrimary || b2 }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoadingData, on: self)
        .store(in: &subscriptions)

        let isRenderingMapOverlay = Publishers.CombineLatest(
            isGeneratingWorksiteMarkers,
            mapDotsOverlay.isBusy
                .eraseToAnyPublisher()
                .removeDuplicates()
        )
            .map { b0, b1 in b0 || b1 }
            .eraseToAnyPublisher()
        Publishers.CombineLatest4(
            incidentsLoading,
            mapBoundsManager.isDeterminingBoundsPublisher.eraseToAnyPublisher(),
            isRenderingMapOverlay,
            isDelayingRegionBug
        )
            .receive(on: RunLoop.main)
            .map { b0, b1, b2, b3 in b0 || b1 || b2 || b3 }
            .assign(to: \.isMapBusy, on: self)
            .store(in: &subscriptions)

        tableViewDataLoader.isLoading
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingTableViewData, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $isLoadingTableViewData,
            transferWorkTypeProvider.isPendingTransferPublisher
        )
        .map { isLoading, isPendingTransfer in !(isLoading || isPendingTransfer) }
        .receive(on: RunLoop.main)
        .assign(to: \.isTableEditable, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeIncidentsData() {
        mapMarkersChangeSetSubject
            .receive(on: RunLoop.main)
            .assign(to: \.mapMarkersChangeSet, on: self)
            .store(in: &subscriptions)

        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)

        incidentIdPublisher
            .receive(on: RunLoop.main)
            .sink {
                self.tileRefreshedTimestamp = self.epochZero
                self.mapDotsOverlay.setIncident($0, 0, clearCache: true)
                self.reloadMapOverlay()
            }
            .store(in: &subscriptions)
    }

    private func subscribeCameraBounds() {
        mapBoundsManager.incidentBoundsPublisher
            .eraseToAnyPublisher()
            .map { MapViewCameraBounds($0) }
            .receive(on: RunLoop.main)
            .assign(to: \.incidentMapBounds, on: self)
            .store(in: &subscriptions)

        mapBoundsManager.mapCameraBoundsPublisher
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { bounds in
                var updateBounds = !self.hasDisappeared
                if self.hasDisappeared {
                    self.hasDisappeared = false
                    if self.incidentId != self.incidentOnDisappear {
                        self.incidentOnDisappear = self.incidentId
                        updateBounds = true
                    }
                }

                if updateBounds {
                    self.mapCameraBounds = bounds
                }
            })
            .store(in: &subscriptions)
    }

    private func subscribeWorksiteInBounds() {
        let worksitesInBounds = Publishers.CombineLatest3(
            qsm.worksiteQueryState,
            incidentWorksitesCount,
            worksiteInteractor.caseChangesPublisher.eraseToAnyPublisher()
        )
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { (wqs, _, changedCase) in
                self.latestBoundedMarkersPublisher.publisher {
                    let queryIncidentId = wqs.incidentId
                    let queryFilters = wqs.filters

                    let isZoomedOut = wqs.zoom < CasesConstant.MapMarkersZoomLevel
                    if wqs.isTableView ||
                        queryIncidentId == EmptyIncident.id ||
                        isZoomedOut
                    {
                        return IncidentAnnotations(
                            queryIncidentId,
                            queryFilters,
                            isClean: isZoomedOut
                        )
                    }

                    _ = self.mapAnnotationsExchanger.onAnnotationStateChange(
                        queryIncidentId,
                        queryFilters,
                        changedCase
                    )

                    try Task.checkCancellation()

                    var annotations = [WorksiteAnnotationMapMark]()
                    self.isGeneratingWorksiteMarkers.value = true
                    do {
                        defer { self.isGeneratingWorksiteMarkers.value = false }

                        annotations = try await self.generateWorksiteMarkers(wqs)
                    } catch {
                        self.logger.logError(error)
                    }

                    try Task.checkCancellation()

                    return IncidentAnnotations(
                        queryIncidentId,
                        queryFilters,
                        changedCase,
                        annotations
                    )
                }
            }
            .switchToLatest()
            .share()

        worksitesInBounds
            .map { incidentAnnotations in
                return self.latestMapMarkersPublisher.publisher {
                    if incidentAnnotations.isClean {
                        self.mapAnnotationsExchanger.onClean(
                            incidentAnnotations.incidentId,
                            incidentAnnotations.filters,
                            incidentAnnotations.changedCase
                        )
                        throw CancellationError()
                    }

                    let changes = try self.mapAnnotationsExchanger.getChange(incidentAnnotations)

                    try Task.checkCancellation()

                    return changes
                }
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { changes in
                if changes.annotations.incidentId == self.incidentId,
                    changes.annotations.filters == self.filterRepository.casesFilters {
                    self.mapMarkersChangeSetSubject.value = changes
                }
            })
            .store(in: &subscriptions)

        let totalCasesCount = Publishers.CombineLatest3(
            $isLoadingData,
            incidentIdPublisher,
            incidentWorksitesCount,
        )
            .throttle(for: .seconds(0.1), scheduler: RunLoop.current, latest: true)
            .map { (isLoading, incidentId, worksitesCount) in
                if incidentId != worksitesCount.id {
                    return -1
                }

                let totalCount = worksitesCount.filteredCount
                if totalCount == 0 && isLoading {
                    return -1
                }

                return totalCount
            }
            .eraseToAnyPublisher()
            .share()

        let t = self.translator
        Publishers.CombineLatest(
            totalCasesCount,
            qsm.isTableViewSubject
        )
        .filter { (_, isTable) in isTable }
        .map { (totalCount, _) in
            if totalCount < 0 { return "" }
            if totalCount == 1 { return "\(totalCount) \(t.t("casesVue.case"))" }
            return "\(totalCount) \(t.t("casesVue.cases"))"
        }
        .receive(on: RunLoop.main)
        .assign(to: \.casesCountTableText, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest3(
            totalCasesCount,
            qsm.worksiteQueryState,
            worksitesInBounds
        )
        .map { (totalCount, wqs, incidentAnnotations) in
            if wqs.isTableView ||
                totalCount < 0 ||
                incidentAnnotations.incidentId != wqs.incidentId ||
                incidentAnnotations.filters != wqs.filters {
                return ""
            }

            let markers = incidentAnnotations.annotations

            var visibleCount = markers.filter { !$0.isFilteredOut }.count
            if visibleCount > totalCount {
                // TODO: Fix if this continues occuring
                self.logger.logDebug("Visible count \(visibleCount) / total \(totalCount)")
                visibleCount = totalCount
            }

            if visibleCount == totalCount || visibleCount == 0 {
                if visibleCount == 0 {
                    return t.t("info.t_of_t_cases").replacingOccurrences(of: "{visible_count}", with: "\(totalCount)")
                } else if totalCount == 1 {
                    return t.t("info.1_of_1_case")
                } else {
                    return t.t("info.t_of_t_cases").replacingOccurrences(of: "{visible_count}", with: "\(totalCount)")
                }
            } else {
                return t.t("info.v_of_t_cases")
                    .replacingOccurrences(of: "{visible_count}", with: "\(visibleCount)")
                    .replacingOccurrences(of: "{total_count}", with: "\(totalCount)")
            }
        }
        .receive(on: RunLoop.main)
        .assign(to: \.casesCountMapText, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest(
            $casesCountMapText,
            $isLoadingData
        )
        .map { countText, loading in
            countText.isNotBlank || loading
        }
        .receive(on: RunLoop.main)
        .assign(to: \.hasCasesCountProgress, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeDataPullStats() {
        dataPullReporter.incidentDataPullStats.eraseToAnyPublisher()
            .map { stats in
                let showProgress = stats.isOngoing && stats.isPullingWorksites
                let isSecondary = stats.pullType == .worksitesAdditional
                let progress = stats.progress
                return DataProgressMetrics(
                    isSecondaryData: isSecondary,
                    showProgress: showProgress,
                    progress: progress
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.dataProgress, on: self)
            .store(in: &subscriptions)

        dataPullReporter.onIncidentDataPullComplete.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { _ in
                self.filterRepository.reapplyFilters()
            }
            .store(in: &subscriptions)
    }

    private func subscribeViewState() {
        qsm.isTableViewSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isTableView, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSortBy() {
        // App preferences must be the single source of truth and other states computed.
        // Preferences > query state > view model <> view
        appPreferences.preferences
            .eraseToAnyPublisher()
           .map { $0.tableViewSortBy }
           .removeDuplicates()
           .receive(on: RunLoop.main)
           .sink(receiveValue: { sortBy in
               self.qsm.tableViewSort.value = sortBy
           })
           .store(in: &subscriptions)

        qsm.tableViewSort
            .receive(on: RunLoop.main)
            .assign(to: \.tableViewSort, on: self)
            .store(in: &subscriptions)

        $tableViewSort
            .removeDuplicates()
            .filter { $0 != .none }
            .sink { sortBy in
                self.changeTableSort(sortBy)
            }
            .store(in: &subscriptions)
    }

    private func subscribeTableData() {
        tableSortResultsMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.tableSortResultsMessage, on: self)
            .store(in: &subscriptions)

        tableViewDataLoader.worksitesChangingClaimAction
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.worksitesChangingClaimAction, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            incidentWorksitesCount,
            $worksitesChangingClaimAction,
            qsm.worksiteQueryState
        )
            .map { (_, _, wqs) in
                if (!wqs.isTableView) {
                    return Just([WorksiteDistance]()).eraseToAnyPublisher()
                }

                self.tableSortResultsMessageSubject.value = ""
                return self.latestTableDataPublisher.publisher {
                    do {
                        return try await self.fetchTableData(wqs)
                    } catch {
                        self.logger.logError(error)
                    }
                    return []
                }
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.tableData, on: self)
            .store(in: &subscriptions)

        changeClaimActionErrorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.changeClaimActionErrorMessage, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLocationStatus() {
        locationManager.$locationPermission
            .receive(on: RunLoop.main)
            .sink {
                if let status = $0,
                   self.locationManager.isAuthorized(status) {
                    self.isMyLocationEnabled = true

                    if self.isTableView {
                        let sortBy = self.pendingTableSort.exchange(AtomicSortBy(.none), ordering: .relaxed).value
                        if sortBy != .none {
                            self.setTableSortBy(sortBy)
                        }
                        self.qsm.locationPermission.value = true
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeFilterCount() {
        filterRepository.filtersCount
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.filtersCount, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeMapTiles() {
        Publishers.CombineLatest3(
            incidentWorksitesCount,
            dataPullReporter.incidentDataPullStats.eraseToAnyPublisher(),
            filterRepository.casesFiltersLocation.eraseToAnyPublisher(),
        )
        .throttle(for: .seconds(0.6), scheduler: RunLoop.current, latest: true)
        .sink { count, stats, _ in
            self.refreshTiles(count, stats)
        }
        .store(in: &subscriptions)
    }

    func syncWorksitesData(_ forceRefreshAll: Bool = false) {
        syncPuller.appPullIncidentData(
            cancelOngoing: false,
            forcePullIncidents: false,
            cacheSelectedIncident: false,
            cacheActiveIncidentWorksites: true,
            cacheFullWorksites: true,
            restartCacheCheckpoint: forceRefreshAll
        )
    }

    private func setTileRendererLocation() {
        mapDotsOverlay.setLocation(locationManager.getLocation())
    }

    func useMyLocation() -> Bool {
        if locationManager.requestLocationAccess() {
            return true
        }

        if locationManager.isDeniedLocationAccess {
            showExplainLocationPermission = true
        }

        return false
    }

    private func reloadMapOverlay() {
        if let map = mapView,
           let renderer = map.renderer(for: mapDotsOverlay) as? MKTileOverlayRenderer {
            renderer.reloadData()
        }
    }

    private func refreshTiles(
        _ idCount: IncidentIdWorksiteCount,
        _ pullStats: IncidentDataPullStats,
    ) {
        if mapDotsOverlay.tilesIncident != idCount.id ||
            idCount.id != pullStats.incidentId {
            return
        }

        let now = Date.now

        if pullStats.isEnded {
            tileRefreshedTimestamp = now
            mapDotsOverlay.setIncident(idCount.id, idCount.totalCount, clearCache: true)
            reloadMapOverlay()
            return
        }

        if !pullStats.isStarted || idCount.totalCount == 0 {
            return
        }

        let sinceLastRefresh = tileRefreshedTimestamp.distance(to: now)
        let refreshTiles = tileRefreshedTimestamp == epochZero ||
        pullStats.startTime.distance(to: now) > tileClearRefreshInterval &&
        sinceLastRefresh > tileClearRefreshInterval
        if (refreshTiles) {
            tileRefreshedTimestamp = now
            mapDotsOverlay.setIncident(idCount.id, idCount.totalCount, clearCache: true)
            reloadMapOverlay()
        }
    }

    func onAddMapAnnotations(_ changes: AnnotationsChangeSet) {
        mapAnnotationsExchanger.onApplied(changes)
    }

    private func generateWorksiteMarkers(_ wqs: WorksiteQueryState) async throws -> [WorksiteAnnotationMapMark] {
        let id = wqs.incidentId
        let sw = wqs.coordinateBounds.southWest
        let ne = wqs.coordinateBounds.northEast
        let marksQuery = try await mapMarkerManager.queryWorksitesInBounds(id, sw, ne, wqs.filters)

        let marks = marksQuery.0
        let markOffsets = try mapMarkerManager.denseMarkerOffsets(marks, qsm.mapZoomSubject.value)

        try Task.checkCancellation()

        let now = Date.now
        return marks.enumerated().map { (index, mark) in
            let isSelected = worksiteInteractor.wasCaseSelected(mark.incidentId, mark.id, reference: now)
            let offset = index < markOffsets.count ? markOffsets[index] : mapMarkerManager.zeroOffset
            return mark.asAnnotationMapMark(mapCaseIconProvider, isSelected, offset)
        }
    }

    // Compensates for inexact altitude-zoom level derivations
    func onZoomIncident() {
        onZoomIncidentTimestamp = Date.now
    }

    func onMapCameraChange(
        _ zoom: Double,
        _ region: MKCoordinateRegion,
        _ didAnimate: Bool
    ) {
        // Workaround for zoom level derivation from altitude
        var zoom = zoom
        if CasesConstant.MapMarkersZoomLevel > zoom {
            let onZoomDelta = Date.now.timeIntervalSince(onZoomIncidentTimestamp)
            if onZoomDelta.seconds < 1,
               CasesConstant.MapMarkersZoomLevel - zoom < 0.3 {
                zoom = CasesConstant.MapMarkersZoomLevel
            }
        }

        qsm.mapZoomSubject.value = zoom

        let center = region.center
        let span = region.span
        let halfSpan = MKCoordinateSpan(
            latitudeDelta: span.latitudeDelta / 2,
            longitudeDelta: span.longitudeDelta / 2
        )
        let southWest = center.subtract(halfSpan).latLng
        let northEast = center.add(halfSpan).latLng

        qsm.mapBoundsSubject.value = CoordinateBounds(
            southWest: southWest,
            northEast: northEast
        )

        mapBoundsManager.cacheBounds(LatLngBounds(
            southWest: southWest,
            northEast: northEast
        ))

        // TODO: Redesign entire map (data) state
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

    func toggleTableView() {
        qsm.isTableViewSubject.value.toggle()
    }

    private func fetchTableData(_ wqs: WorksiteQueryState) async throws -> [WorksiteDistance] {
        let filters = wqs.filters
        var sortBy = wqs.tableViewSort

        let isDistanceSort = sortBy == .nearest
        let locationCoordinates = locationManager.getLocation()?.coordinate
        let hasLocation = locationCoordinates != nil
        if (isDistanceSort && !hasLocation) {
            sortBy = .caseNumber
        }

        try Task.checkCancellation()

        let worksites = try await worksitesRepository.getTableData(
            incidentId: wqs.incidentId,
            filters: filters,
            sortBy: sortBy,
            coordinates: locationCoordinates
        )

        let strideCount = 100
        let locationLatitude = locationCoordinates?.latitude ?? 0.0
        let locationLongitude = locationCoordinates?.longitude ?? 0.0
        let locationLatitudeRad = locationLatitude.radians
        let locationLongitudeRad = locationLongitude.radians
        let tableData = try worksites.enumerated().map { (i, tableData) in
            if (i % strideCount == 0) {
                try Task.checkCancellation()
            }

            let distance = hasLocation ? {
                let worksite = tableData.worksite
                return haversineDistance(
                    locationLatitudeRad, locationLongitudeRad,
                    worksite.latitude.radians, worksite.longitude.radians
                ).kmToMiles
            }() : -1.0
            return WorksiteDistance(
                data: tableData,
                distanceMiles: distance
            )
        }

        if isDistanceSort && tableData.isEmpty {
            tableSortResultsMessageSubject.value =
            translator.t("worksiteFilters.no_cases_found_radius")
                .replacingOccurrences(
                    of: "{search_radius}",
                    with: "\(Int(tableDataDistanceSortSearchRadius))"
                )
        }

        return tableData
    }

    private func setTableSortBy(_ sortBy: WorksiteSortBy) {
        appPreferences.setTableViewSortBy(sortBy)
    }

    private func changeTableSort(_ sortBy: WorksiteSortBy) {
        if sortBy == .nearest {
            if locationManager.requestLocationAccess() {
                setTableSortBy(sortBy)
            } else {
                pendingTableSort.store(AtomicSortBy(sortBy), ordering: .relaxed)

                if locationManager.isDeniedLocationAccess {
                    showExplainLocationPermission = true
                }
            }

            if !locationManager.hasLocationAccess {
                // TODO: How to revert view's selected sort by without too much complexity?
            }
        } else {
            setTableSortBy(sortBy)
        }
    }

    func onOpenCaseFlags(_ worksite: Worksite) {
        Task {
            if await tableViewDataLoader.loadWorksiteForAddFlags(worksite) {
                openWorksiteAddFlag.store(true, ordering: .sequentiallyConsistent)
                Task { @MainActor in
                    openWorksiteAddFlagCounter.value += 1
                }
            }
        }
    }

    func onWorksiteClaimAction(
        _ worksite: Worksite,
        _ claimAction: TableWorksiteClaimAction
    ) {
        changeClaimActionErrorMessageSubject.value = ""
        Task {
            let result = await tableViewDataLoader.onWorkTypeClaimAction(
                worksite,
                claimAction,
                transferWorkTypeProvider
            )
            if result.errorMessage.isNotBlank {
                changeClaimActionErrorMessageSubject.value = result.errorMessage
            }
        }
    }

    func takeOpenWorksiteAddFlag() -> Bool {
        openWorksiteAddFlag.exchange(false, ordering: .sequentiallyConsistent)
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

struct WorksiteDistance {
    let data: TableDataWorksite
    let distanceMiles: Double

    var worksite: Worksite { data.worksite }
    var claimStatus: TableWorksiteClaimStatus { data.claimStatus }
}

private class AtomicSortBy: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicSortBy>

    let value: WorksiteSortBy

    init(_ value: WorksiteSortBy = .none) {
        self.value = value
    }
}

struct DataProgressMetrics {
    let isSecondaryData: Bool
    let showProgress: Bool
    let progress: Double

    let isLoadingPrimary: Bool

    init(
        isSecondaryData: Bool = false,
        showProgress: Bool = false,
        progress: Double = 0.0
    ) {
        self.isSecondaryData = isSecondaryData
        self.showProgress = showProgress
        self.progress = progress
        isLoadingPrimary = showProgress && !isSecondaryData
    }
}
