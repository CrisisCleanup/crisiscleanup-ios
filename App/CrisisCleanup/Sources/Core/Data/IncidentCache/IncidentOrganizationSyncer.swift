import Combine
import Foundation

public protocol OrganizationsSyncer {
    func sync(_ incidentId: Int64) async throws
}

class IncidentOrganizationSyncer: OrganizationsSyncer {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let networkDataCache: IncidentOrganizationsDataCache
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let personContactDao: PersonContactDao
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let organizationFields = [
        "id",
        "name",
        "affiliates",
        "is_active",
        "primary_location",
        "secondary_location",
        "type_t",
        "primary_contacts",
    ]

    private let dataPullStatsSubject = CurrentValueSubject<IncidentDataPullStats, Never>(IncidentDataPullStats())
    let dataPullStats: any Publisher<IncidentDataPullStats, Never>

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        networkDataCache: IncidentOrganizationsDataCache,
        incidentOrganizationDao: IncidentOrganizationDao,
        personContactDao: PersonContactDao,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.networkDataCache = networkDataCache
        self.incidentOrganizationDao = incidentOrganizationDao
        self.personContactDao = personContactDao
        self.appVersionProvider = appVersionProvider

        logger = loggerFactory.getLogger("org-syncer")

        dataPullStats = dataPullStatsSubject
    }

    func sync(_ incidentId: Int64) async throws {
        try await saveOrganizationsData(incidentId)
    }

    private func saveOrganizationsData(
        _ incidentId: Int64,
    ) async throws {
        var syncCount = 100
        let syncStart = Date.now

        var requestedCount = 0
        var networkDataOffset = 0
        let pageDataCount = 100
        do {
            while (networkDataOffset < syncCount) {
                let worksitesRequest = try await networkDataSource.getIncidentOrganizations(
                    incidentId: incidentId,
                    fields: organizationFields,
                    limit: pageDataCount,
                    offset: networkDataOffset
                )

                syncCount = worksitesRequest?.count ?? 0

                if let results = worksitesRequest?.results {
                    try await networkDataCache.saveOrganizations(
                        incidentId: incidentId,
                        dataIndex: networkDataOffset,
                        expectedCount: syncCount,
                        organizations: results
                    )
                } else {
                    break
                }

                networkDataOffset += pageDataCount

                try Task.checkCancellation()

                requestedCount = min(networkDataOffset, syncCount)
            }
        } catch {
            if error is CancellationError {
                throw error
            }
            logger.logError(error)
        }

        var dbSaveCount = 0
        for dbSaveOffset in stride(from: 0, to: requestedCount, by: pageDataCount) {
            if let cachedData = try networkDataCache.loadOrganizations(
                incidentId,
                dbSaveOffset,
                syncCount
            ) {
                let organizationRecords = cachedData.organizations.asRecords(getContacts: true, getReferences: false)
                let organizations = organizationRecords.organizations
                let primaryContacts = organizationRecords.primaryContacts
                try await incidentOrganizationDao.saveOrganizations(
                    organizations,
                    primaryContacts
                )

                dbSaveCount += pageDataCount
            } else {
                break
            }
        }

        for dbSaveOffset in stride(from: 0, to: requestedCount, by: pageDataCount) {
            if let cachedData = try networkDataCache.loadOrganizations(
                incidentId,
                dbSaveOffset,
                syncCount
            ) {
                let organizationRecords = cachedData.organizations.asRecords(getContacts: false, getReferences: true)
                let organizations = organizationRecords.organizations
                let organizationContactCrossRefs = organizationRecords.organizationToContacts
                let organizationAffiliates = organizationRecords.orgAffiliates
                try await incidentOrganizationDao.saveOrganizationReferences(
                    organizations,
                    organizationContactCrossRefs,
                    organizationAffiliates
                )
            } else {
                break
            }
        }

        if dbSaveCount >= syncCount {
            try await incidentOrganizationDao.upsertStats(
                IncidentOrganizationSyncStatRecord(
                    id: incidentId,
                    targetCount: syncCount,
                    successfulSync: syncStart,
                    appBuildVersionCode: appVersionProvider.buildNumber
                )
            )
        }

        for deleteCacheOffset in stride(from: 0, to: networkDataOffset, by: pageDataCount) {
            await networkDataCache.deleteOrganizations(incidentId, deleteCacheOffset)
        }

        try await personContactDao.trimIncidentOrganizationContacts()
    }
}
