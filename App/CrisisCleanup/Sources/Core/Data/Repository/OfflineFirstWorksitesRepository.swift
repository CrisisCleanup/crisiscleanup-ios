import Combine
import CoreLocation
import Foundation

class OfflineFirstWorksitesRepository: WorksitesRepository, IncidentDataPullReporter {
    private let dataSource: CrisisCleanupNetworkDataSource
    private let writeApi: CrisisCleanupWriteApi
    private let worksitesSyncer: WorksitesSyncer
    private let worksiteSyncStatDao: WorksiteSyncStatDao
    private let worksiteDao: WorksiteDao
    private let recentWorksiteDao: RecentWorksiteDao
    private let workTypeTransferRequestDao: WorkTypeTransferRequestDao
    private let accountDataRepository: AccountDataRepository
    private let languageTranslationsRepository: LanguageTranslationsRepository
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    var isLoading: any Publisher<Bool, Never>

    private let syncWorksitesFullIncidentIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    var syncWorksitesFullIncidentId: any Publisher<Int64, Never>

    private let isDeterminingWorksitesCountSubject = CurrentValueSubject<Bool, Never>(false)
    var isDeterminingWorksitesCount: any Publisher<Bool, Never>

    var incidentDataPullStats: any Publisher<IncidentDataPullStats, Never>

    private let orgIdPublisher: AnyPublisher<Int64, Never>
    private let organizationAffiliatesPublisher: AnyPublisher<Set<Int64>, Never>

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        writeApi: CrisisCleanupWriteApi,
        worksitesSyncer: WorksitesSyncer,
        worksiteSyncStatDao: WorksiteSyncStatDao,
        worksiteDao: WorksiteDao,
        recentWorksiteDao: RecentWorksiteDao,
        workTypeTransferRequestDao: WorkTypeTransferRequestDao,
        accountDataRepository: AccountDataRepository,
        languageTranslationsRepository: LanguageTranslationsRepository,
        organizationsRepository: OrganizationsRepository,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.writeApi = writeApi
        self.worksitesSyncer = worksitesSyncer
        self.worksiteSyncStatDao = worksiteSyncStatDao
        self.worksiteDao = worksiteDao
        self.recentWorksiteDao = recentWorksiteDao
        self.accountDataRepository = accountDataRepository
        self.languageTranslationsRepository = languageTranslationsRepository
        self.workTypeTransferRequestDao = workTypeTransferRequestDao
        self.appVersionProvider = appVersionProvider
        logger = loggerFactory.getLogger("worksites-repository")

        isLoading = isLoadingSubject
        syncWorksitesFullIncidentId = syncWorksitesFullIncidentIdSubject
        isDeterminingWorksitesCount = isDeterminingWorksitesCountSubject
        incidentDataPullStats = worksitesSyncer.dataPullStats

        orgIdPublisher = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .asyncMap { $0.org.id }
            .eraseToAnyPublisher()
        organizationAffiliatesPublisher = orgIdPublisher
            .map { orgId in organizationsRepository.getOrganizationAffiliateIds(orgId) }
            .eraseToAnyPublisher()
    }

    func streamIncidentWorksitesCount(incidentIdStream: any Publisher<Int64, Never>) -> any Publisher<Int, Never> {
        // TODO: Do
        Just(0)
    }

    func streamIncidentWorksitesCount(_ id: Int64) -> any Publisher<Int, Never> {
        worksiteDao.streamIncidentWorksitesCount(id)
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
        offset: Int
    ) throws -> [WorksiteMapMark] {
        try worksiteDao.getWorksitesMapVisual(
            incidentId,
            south: latitudeSouth,
            north: latitudeNorth,
            west: longitudeWest,
            east: longitudeEast,
            limit: limit,
            offset: offset
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
        } catch {
            if error is CancellationError {
                throw error
            }

            // Updating sync stats here (or in finally) could overwrite "concurrent" sync that previously started. Think it through before updating sync attempt.

            logger.logError(error)
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
        try worksiteDao.getUnsyncedChangeCount(worksiteId)
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

        let records = try await worksiteDao.loadTableWorksites(
            incidentId: incidentId,
            filters: filters,
            organizationAffiliates: affiliateIds,
            sortBy: sortBy,
            coordinates: coordinates,
            searchRadius: searchRadius,
            count: count
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
