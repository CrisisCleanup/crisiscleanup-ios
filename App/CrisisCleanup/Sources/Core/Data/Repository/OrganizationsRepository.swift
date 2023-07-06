import Combine

public protocol OrganizationsRepository {
    var organizationNameLookup: any Publisher<[Int64: String], Never> { get }

    var organizationLookup: any Publisher<[Int64: IncidentOrganization], Never> { get }

    func getOrganizationAffiliateIds(_ organizationId: Int64) -> Set<Int64>

    func getNearbyClaimingOrganizations(
        _ latitude: Double,
        _ longitude: Double
    ) async -> [IncidentOrganization]

    // TODO: When flags are developed
    // func getMatchingOrganizations(q: String) -> [OrganizationIdName]
}

class OfflineFirstOrganizationsRepository: OrganizationsRepository {
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let logger: AppLogger

    let organizationNameLookup: any Publisher<[Int64: String], Never>
    let organizationLookup: any Publisher<[Int64: IncidentOrganization], Never>

    init(
        incidentOrganizationDao: IncidentOrganizationDao,
        networkDataSource: CrisisCleanupNetworkDataSource,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentOrganizationDao = incidentOrganizationDao
        self.networkDataSource = networkDataSource
        self.logger = loggerFactory.getLogger("incident-organization-dao")
        self.organizationNameLookup = incidentOrganizationDao.streamOrganizationNames()
            .assertNoFailure()
            .map { $0.asLookup() }
        self.organizationLookup = incidentOrganizationDao.streamOrganizations()
            .assertNoFailure()
            .map { orgs in
                orgs.map { $0.asExternalModel() }
                    .associateBy { $0.id }
            }
    }

    func getOrganizationAffiliateIds(_ organizationId: Int64) -> Set<Int64> {
        var affiliateIds = Set(incidentOrganizationDao.getAffiliateOrganizationIds(organizationId))
        affiliateIds.insert(organizationId)
        return affiliateIds
    }

    func getNearbyClaimingOrganizations(
        _ latitude: Double,
        _ longitude: Double
    ) async -> [IncidentOrganization] {
        do {
            let networkOrganizations = try await networkDataSource.getNearbyOrganizations(latitude, longitude)
            let records = networkOrganizations.asRecords(getContacts: true, getReferences: true)
            try await incidentOrganizationDao.saveOrganizations(
                records.organizations,
                records.primaryContacts
            )
            try await incidentOrganizationDao.saveOrganizationReferences(
                records.organizations,
                records.organizationToContacts,
                records.orgAffiliates
            )

            let organizationIds = records.organizations.map { $0.id }
            return try incidentOrganizationDao.getOrganizations(organizationIds)
                .map { $0.asExternalModel() }
        } catch {
            logger.logError(error)
        }
        return []
    }
}
