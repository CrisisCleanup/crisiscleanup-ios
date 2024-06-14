import Combine
import CoreLocation
import Foundation

class OfflineFirstWorksitesRepository: WorksitesRepository, IncidentDataPullReporter {
    private let dataSource: CrisisCleanupNetworkDataSource
    private let writeApi: CrisisCleanupWriteApi
    private let worksitesSyncer: WorksitesSyncer
    private let worksitesSecondarySyncer: WorksitesSecondaryDataSyncer
    private let worksiteSyncStatDao: WorksiteSyncStatDao
    private let worksiteDao: WorksiteDao
    private let recentWorksiteDao: RecentWorksiteDao
    private let workTypeTransferRequestDao: WorkTypeTransferRequestDao
    private let accountDataRepository: AccountDataRepository
    private let languageTranslationsRepository: LanguageTranslationsRepository
    private let filtersRepository: CasesFilterRepository
    private let locationManager: LocationManager
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    var isLoading: any Publisher<Bool, Never>

    private let syncWorksitesFullIncidentIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    var syncWorksitesFullIncidentId: any Publisher<Int64, Never>

    private let isDeterminingWorksitesCountSubject = CurrentValueSubject<Bool, Never>(false)
    var isDeterminingWorksitesCount: any Publisher<Bool, Never>

    var incidentDataPullStats: any Publisher<IncidentDataPullStats, Never>
    var incidentSecondaryDataPullStats: any Publisher<IncidentDataPullStats, Never>
    var onIncidentDataPullComplete: any Publisher<Int64, Never>

    private let orgIdPublisher: AnyPublisher<Int64, Never>
    private let organizationAffiliatesPublisher: AnyPublisher<Set<Int64>, Never>

    private let organizationLocationAreaBounds: AnyPublisher<OrganizationLocationAreaBounds, Never>

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        writeApi: CrisisCleanupWriteApi,
        worksitesSyncer: WorksitesSyncer,
        worksitesSecondarySyncer: WorksitesSecondaryDataSyncer,
        worksiteSyncStatDao: WorksiteSyncStatDao,
        worksiteDao: WorksiteDao,
        recentWorksiteDao: RecentWorksiteDao,
        workTypeTransferRequestDao: WorkTypeTransferRequestDao,
        accountDataRepository: AccountDataRepository,
        languageTranslationsRepository: LanguageTranslationsRepository,
        organizationsRepository: OrganizationsRepository,
        filtersRepository: CasesFilterRepository,
        locationManager: LocationManager,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.writeApi = writeApi
        self.worksitesSyncer = worksitesSyncer
        self.worksitesSecondarySyncer = worksitesSecondarySyncer
        self.worksiteSyncStatDao = worksiteSyncStatDao
        self.worksiteDao = worksiteDao
        self.recentWorksiteDao = recentWorksiteDao
        self.accountDataRepository = accountDataRepository
        self.languageTranslationsRepository = languageTranslationsRepository
        self.workTypeTransferRequestDao = workTypeTransferRequestDao
        self.filtersRepository = filtersRepository
        self.locationManager = locationManager
        self.appVersionProvider = appVersionProvider
        logger = loggerFactory.getLogger("worksites-repository")

        isLoading = isLoadingSubject
        syncWorksitesFullIncidentId = syncWorksitesFullIncidentIdSubject
        isDeterminingWorksitesCount = isDeterminingWorksitesCountSubject

        incidentDataPullStats = worksitesSyncer.dataPullStats
        incidentSecondaryDataPullStats = worksitesSecondarySyncer.dataPullStats
        onIncidentDataPullComplete = worksitesSecondarySyncer.onFullDataPullComplete

        orgIdPublisher = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map { $0.org.id }
            .eraseToAnyPublisher()
        organizationAffiliatesPublisher = orgIdPublisher
            .map { orgId in organizationsRepository.getOrganizationAffiliateIds(orgId, addOrganizationId: true) }
            .eraseToAnyPublisher()

        organizationLocationAreaBounds = orgIdPublisher
            .filter { $0 > 0 }
            .map { organizationsRepository.streamPrimarySecondaryAreas($0).eraseToAnyPublisher() }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    private let latestIncidentWorksitesCountPublisher = LatestAsyncPublisher<IncidentIdWorksiteCount>()
    func streamIncidentWorksitesCount(_ incidentIdStream: any Publisher<Int64, Never>) -> any Publisher<IncidentIdWorksiteCount, Never> {
        let incidentIdPublisher = incidentIdStream.eraseToAnyPublisher()
        return Publishers.CombineLatest4(
            incidentIdPublisher,
            incidentIdPublisher
                .map { id in self.worksiteDao.streamIncidentWorksitesCount(id).eraseToAnyPublisher() }
                .switchToLatest()
                .assertNoFailure()
                .eraseToAnyPublisher(),
            filtersRepository.casesFiltersLocation.eraseToAnyPublisher(),
            organizationLocationAreaBounds
        )
        .debounce(for: .seconds(0.1), scheduler: RunLoop.current)
        .map { id, totalCount, filtersLocation, areaBounds in
            self.latestIncidentWorksitesCountPublisher.publisher {
                let filters = filtersLocation.0
                if !filters.isDefault {
                    self.isDeterminingWorksitesCountSubject.value = true
                    do {
                        defer { self.isDeterminingWorksitesCountSubject.value = false }

                        let organizationAffiliates = try await self.organizationAffiliatesPublisher.asyncFirst()
                        return try await self.worksiteDao.getWorksitesCount(
                            id,
                            totalCount,
                            filters,
                            organizationAffiliates,
                            self.locationManager.getLocation(),
                            areaBounds
                        )
                    } catch {
                        self.logger.logError(error)
                    }
                }

                self.isDeterminingWorksitesCountSubject.value = false
                return IncidentIdWorksiteCount(
                    id: id,
                    totalCount: totalCount,
                    filteredCount: totalCount
                )
            }
        }
        .switchToLatest()
        .assertNoFailure()
    }

    func getWorksite(_ id: Int64) async throws -> Worksite? {
        try await worksiteDao.getWorksite(id)?.asExternalModel(
            orgIdPublisher.asyncFirst(),
            languageTranslationsRepository
        )
        .worksite
    }

    func streamLocalWorksite(_ worksiteId: Int64) -> any Publisher<LocalWorksite?, Never> {
        worksiteDao.streamLocalWorksite(worksiteId)
            .assertNoFailure()
            .asyncMap({ localWorksite in
                let orgId = try! await self.orgIdPublisher.asyncFirst()
                return localWorksite?.asExternalModel(
                    orgId,
                    self.languageTranslationsRepository
                )
            })
    }

    func streamRecentWorksites(_ incidentId: Int64) -> any Publisher<[WorksiteSummary], Never> {
        recentWorksiteDao.streamRecentWorksites(incidentId)
            .assertNoFailure()
    }

    func getWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeWest: Double,
        longitudeEast: Double,
        limit: Int,
        offset: Int,
        coordinates: CLLocation?,
        casesFilters: CasesFilter
    ) async throws -> [WorksiteMapMark] {
        try await worksiteDao.getWorksitesMapVisual(
            incidentId,
            south: latitudeSouth,
            north: latitudeNorth,
            west: longitudeWest,
            east: longitudeEast,
            limit: limit,
            offset: offset
        )
        .filterMapVisuals(
            casesFilters,
            organizationAffiliatesPublisher.asyncFirst(),
            organizationLocationAreaBounds.asyncFirst(),
            coordinates
        )
    }

    func getWorksitesCount(_ incidentId: Int64) throws -> Int {
        try worksiteDao.getWorksitesCount(incidentId)
    }

    func getWorksitesCount(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeLeft: Double,
        longitudeRight: Double
    ) throws -> Int {
        try worksiteDao.getWorksitesCount(
            incidentId,
            south: latitudeSouth,
            north: latitudeNorth,
            west: longitudeLeft,
            east: longitudeRight
        )
    }

    private func queryUpdatedSyncStats(
        _ incidentId: Int64,
        _ reset: Bool
    ) async throws -> IncidentDataSyncStats {
        if !reset {
            if let syncStats = try worksiteSyncStatDao.getSyncStats(incidentId) {
                if !syncStats.isDataVersionOutdated {
                    return syncStats
                }
            }
        }

        let syncStart = Date.now
        let worksitesCount =
            await worksitesSyncer.networkWorksitesCount(incidentId, Date(timeIntervalSince1970: 0))
        let syncStats = IncidentDataSyncStats(
            incidentId: incidentId,
            syncStart: syncStart,
            dataCount: worksitesCount,
            // TODO: Preserve previous attempt metrics (if used)
            syncAttempt: SyncAttempt(
                successfulSeconds: 0,
                attemptedSeconds: 0,
                attemptedCounter: 0
            ),
            appBuildVersionCode: appVersionProvider.buildNumber
        )
        try await worksiteSyncStatDao.upsertStats(syncStats.asWorksiteSyncStatsRecord())
        return syncStats
    }

    func refreshWorksites(
        _ incidentId: Int64,
        forceQueryDeltas: Bool,
        forceRefreshAll: Bool
    ) async throws {
        if incidentId == EmptyIncident.id {
            return
        }

        // TODO: Enforce single process syncing per incident since this may be very long running

        isLoadingSubject.value = true
        do {
            defer {
                isLoadingSubject.value = false
            }

            let syncStats = try await queryUpdatedSyncStats(incidentId, forceRefreshAll)
            let savedWorksitesCount = try worksiteDao.getWorksitesCount(incidentId)
            if syncStats.syncAttempt.shouldSyncPassively() ||
                savedWorksitesCount < syncStats.dataCount ||
                forceQueryDeltas
            {
                try await worksitesSyncer.sync(incidentId, syncStats)
            }

            try await syncAdditional(incidentId)
        } catch {
            if error is CancellationError {
                throw error
            }

            // Updating sync stats here (or in finally) could overwrite "concurrent" sync that previously started. Think it through before updating sync attempt.

            logger.logError(error)
        }
    }

    private func syncAdditional(_ incidentId: Int64) async throws {
        if let syncStats = try worksiteSyncStatDao.getFullSyncStats(incidentId),
           syncStats.hasSyncedCore {
            try await worksitesSecondarySyncer.sync(incidentId, syncStats.secondaryStats)
        }
    }

    func getWorksiteSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncStats? {
        try worksiteSyncStatDao.getSyncStats(incidentId)
    }

    func syncNetworkWorksite(_ worksite: NetworkWorksiteFull, _ syncedAt: Date) async throws -> Bool {
        let records = worksite.asRecords()
        return try await worksiteDao.syncNetworkWorksite(records, syncedAt)
    }

    func getLocalId(_ networkWorksiteId: Int64) throws -> Int64 {
        try worksiteDao.getWorksiteId(networkWorksiteId)
    }

    func pullWorkTypeRequests(_ networkWorksiteId: Int64) async throws {
        do {
            let workTypeRequests = try await dataSource.getWorkTypeRequests(networkWorksiteId)
            if workTypeRequests.isNotEmpty {
                let worksiteId = try worksiteDao.getWorksiteId(networkWorksiteId)
                let records = workTypeRequests.map { $0.asRecord(worksiteId) }
                try await workTypeTransferRequestDao.syncUpsert(records)
            }
        } catch {
            logger.logError(error)
        }
    }

    func setRecentWorksite(
        incidentId: Int64,
        worksiteId: Int64,
        viewStart: Date
    ) {
        Task {
            do {
                try await recentWorksiteDao.upsert(RecentWorksiteRecord(
                    id: worksiteId,
                    incidentId: incidentId,
                    viewedAt: viewStart
                ))
            } catch {
                logger.logError(error)
            }
        }
    }

    func getUnsyncedCounts(_ worksiteId: Int64) throws -> [Int] {
        try worksiteDao.getUnsyncedChangeCount(worksiteId, MaxSyncTries)
    }

    func shareWorksite(
        worksiteId: Int64,
        emails: [String],
        phoneNumbers: [String],
        shareMessage: String,
        noClaimReason: String?
    ) async -> Bool {
        do {
            try await writeApi.shareWorksite(
                worksiteId,
                emails,
                phoneNumbers,
                shareMessage,
                noClaimReason
            )

            return true
        } catch {
            logger.logError(error)
        }
        return false
    }

    func getTableData(
        incidentId: Int64,
        filters: CasesFilter,
        sortBy: WorksiteSortBy,
        coordinates: CLLocationCoordinate2D?,
        searchRadius: Double,
        count: Int
    ) async throws -> [TableDataWorksite] {
        let affiliateIds = try await organizationAffiliatesPublisher.asyncFirst()
        let areaBounds = try await organizationLocationAreaBounds.asyncFirst()

        let records = try await worksiteDao.loadTableWorksites(
            incidentId: incidentId,
            filters: filters,
            organizationAffiliates: affiliateIds,
            sortBy: sortBy,
            coordinates: coordinates,
            searchRadius: searchRadius,
            count: count,
            locationAreaBounds: areaBounds
        )

        try Task.checkCancellation()

        let strideCount = 100
        var tableData = [TableDataWorksite]()
        for i in records.indices {
            if i % strideCount == 0 {
                try Task.checkCancellation()
            }

            let worksite = records[i].asExternalModel()
            let claimStatus = worksite.getClaimStatus(affiliateIds)
            let tableRecord = TableDataWorksite(worksite: worksite, claimStatus: claimStatus)
            tableData.append(tableRecord)
        }

        return tableData
    }
}
