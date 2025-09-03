import Combine
import CombineExt
import CoreLocation
import Foundation

class OfflineFirstWorksitesRepository: WorksitesRepository {
    private let dataSource: CrisisCleanupNetworkDataSource
    private let writeApi: CrisisCleanupWriteApi
    private let worksiteDao: WorksiteDao
    private let recentWorksiteDao: RecentWorksiteDao
    private let workTypeTransferRequestDao: WorkTypeTransferRequestDao
    private let accountDataRepository: AccountDataRepository
    private let languageTranslationsRepository: LanguageTranslationsRepository
    private let filtersRepository: CasesFilterRepository
    private let locationManager: LocationManager
    private let phoneNumberParser: PhoneNumberParser
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    var isLoading: any Publisher<Bool, Never>

    private let syncWorksitesFullIncidentIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    var syncWorksitesFullIncidentId: any Publisher<Int64, Never>

    private let isDeterminingWorksitesCountSubject = CurrentValueSubject<Bool, Never>(false)
    var isDeterminingWorksitesCount: any Publisher<Bool, Never>

    private let orgIdPublisher: AnyPublisher<Int64, Never>
    private let organizationAffiliatesPublisher: AnyPublisher<Set<Int64>, Never>

    private let organizationLocationAreaBounds: AnyPublisher<OrganizationLocationAreaBounds, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        writeApi: CrisisCleanupWriteApi,
        worksiteDao: WorksiteDao,
        recentWorksiteDao: RecentWorksiteDao,
        workTypeTransferRequestDao: WorkTypeTransferRequestDao,
        accountDataRepository: AccountDataRepository,
        languageTranslationsRepository: LanguageTranslationsRepository,
        organizationsRepository: OrganizationsRepository,
        filtersRepository: CasesFilterRepository,
        locationManager: LocationManager,
        phoneNumberParser: PhoneNumberParser,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.writeApi = writeApi
        self.worksiteDao = worksiteDao
        self.recentWorksiteDao = recentWorksiteDao
        self.accountDataRepository = accountDataRepository
        self.languageTranslationsRepository = languageTranslationsRepository
        self.workTypeTransferRequestDao = workTypeTransferRequestDao
        self.filtersRepository = filtersRepository
        self.locationManager = locationManager
        self.phoneNumberParser = phoneNumberParser
        self.appVersionProvider = appVersionProvider
        logger = loggerFactory.getLogger("worksites-repository")

        isLoading = isLoadingSubject
        syncWorksitesFullIncidentId = syncWorksitesFullIncidentIdSubject
        isDeterminingWorksitesCount = isDeterminingWorksitesCountSubject

        orgIdPublisher = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map { $0.org.id }
            .removeDuplicates()
            .replay1()
            .eraseToAnyPublisher()
        organizationAffiliatesPublisher = orgIdPublisher
            .map {
                organizationsRepository.getOrganizationAffiliateIds($0, addOrganizationId: true)
            }
            .eraseToAnyPublisher()

        organizationLocationAreaBounds = orgIdPublisher
            .filter { $0 > 0 }
            .flatMapLatest { organizationsRepository.streamPrimarySecondaryAreas($0).eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }

    func streamIncidentWorksitesCount(_ incidentIdStream: any Publisher<Int64, Never>) -> any Publisher<IncidentIdWorksiteCount, Never> {
        let incidentIdPublisher = incidentIdStream.eraseToAnyPublisher()
        let incidentWorksitesCountPublisher = incidentIdPublisher.flatMapLatest { id in
            self.worksiteDao.streamIncidentWorksitesCount(id)
                .map { (id, $0) }
                .assertNoFailure()
        }
        let filtersPublisher = filtersRepository.casesFiltersLocation.eraseToAnyPublisher()

        return Publishers.CombineLatest3(
            incidentWorksitesCountPublisher,
            filtersPublisher,
            organizationLocationAreaBounds,
        )
        .debounce(for: .seconds(0.1), scheduler: RunLoop.current)
        .mapLatest { idCount, filtersLocation, areaBounds in
            let (id, totalCount) = idCount

            let filters = filtersLocation.0
            if !filters.isDefault {
                self.isDeterminingWorksitesCountSubject.value = true
                do {
                    defer { self.isDeterminingWorksitesCountSubject.value = false }

                    let organizationAffiliates = try await self.organizationAffiliatesPublisher.asyncFirst()
                    let result = try await self.worksiteDao.getWorksitesCount(
                        id,
                        totalCount,
                        filters,
                        organizationAffiliates,
                        self.locationManager.getLocation(),
                        areaBounds,
                    )
                    return result
                } catch {
                    self.logger.logError(error)
                }
            }

            return IncidentIdWorksiteCount(
                id: id,
                totalCount: totalCount,
                filteredCount: totalCount,
            )
        }
        .assertNoFailure()
        .eraseToAnyPublisher()
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
            .asyncMap { localWorksite in
                let orgId = try! await self.orgIdPublisher.asyncFirst()
                return localWorksite?.asExternalModel(
                    orgId,
                    self.languageTranslationsRepository
                )
            }
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

    func syncNetworkWorksite(_ worksite: NetworkWorksiteFull, _ syncedAt: Date) async throws -> Bool {
        let records = worksite.asRecords(phoneNumberParser)
        return try await worksiteDao.syncNetworkWorksite(records, syncedAt)
    }

    func syncNetworkWorksite(_ networkWorksiteId: Int64) async {
        let syncedAt = Date.now
        do {
            if let networkWorksite = try await dataSource.getWorksite(networkWorksiteId) {
                _ = try await syncNetworkWorksite(networkWorksite, syncedAt)
            }
        } catch {
            logger.logError(error)
        }
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

    func getRecentWorksitesCenterLocation(_ incidentId: Int64, limit: Int) async throws -> CLLocationCoordinate2D? {
        try recentWorksiteDao.getRecentWorksitesCenterLocation(incidentId, limit: limit)
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
            let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
            try await writeApi.shareWorksite(
                networkWorksiteId,
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

    func processReconciliation(
        validChanges: [NetworkWorksiteChange],
        invalidatedNetworkWorksiteIds: [Int64],
    ) async throws -> [IncidentWorksiteIds] {
        let validIds = validChanges.map {
            IncidentWorksiteIds(
                incidentId: $0.incidentId,
                id: EmptyWorksite.id,
                networkId: $0.worksiteId,
            )
        }
        let worksitesChanged = try await worksiteDao.syncNetworkChangedIncidents(changeCandidates: validIds)
        let worksitesDeleted = try await worksiteDao.syncDeletedWorksites(networkIds: invalidatedNetworkWorksiteIds)

        return worksitesChanged + worksitesDeleted
    }
}
