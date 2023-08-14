import Combine

public protocol OrganizationsRepository {
    var organizationNameLookup: any Publisher<[Int64: String], Never> { get }

    var organizationLookup: any Publisher<[Int64: IncidentOrganization], Never> { get }

    func syncOrganization(
        _ organizationId: Int64,
        force: Bool,
        updateLocations: Bool
    ) async

    func getOrganizationAffiliateIds(_ organizationId: Int64) -> Set<Int64>

    func getNearbyClaimingOrganizations(
        _ latitude: Double,
        _ longitude: Double
    ) async -> [IncidentOrganization]

    func streamPrimarySecondaryAreas(_ organizationId: Int64) -> any Publisher<OrganizationLocationAreaBounds, Never>

    func getMatchingOrganizations(_ q: String) -> [OrganizationIdName]
}

extension OrganizationsRepository {
    func syncOrganization(_ organizationId: Int64) async {
        await syncOrganization(organizationId, force: false, updateLocations: false)
    }
}

class OfflineFirstOrganizationsRepository: OrganizationsRepository {
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let locationDao: LocationDao
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let locationBoundsConverter: LocationBoundsConverter
    private let logger: AppLogger

    let organizationNameLookup: any Publisher<[Int64: String], Never>
    let organizationLookup: any Publisher<[Int64: IncidentOrganization], Never>

    init(
        incidentOrganizationDao: IncidentOrganizationDao,
        locationDao: LocationDao,
        networkDataSource: CrisisCleanupNetworkDataSource,
        locationBoundsConverter: LocationBoundsConverter,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentOrganizationDao = incidentOrganizationDao
        self.locationDao = locationDao
        self.networkDataSource = networkDataSource
        self.locationBoundsConverter = locationBoundsConverter
        logger = loggerFactory.getLogger("organizations-repository")
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

    private func saveOrganizations(_ networkOrganizations: [NetworkIncidentOrganization]) async throws {
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
    }

    func syncOrganization(
        _ organizationId: Int64,
        force: Bool,
        updateLocations: Bool
    ) async {
        if force || incidentOrganizationDao.findOrganization(organizationId) == nil {
            do {
                let networkOrganizations = try await networkDataSource.getOrganizations([organizationId])
                try await saveOrganizations(networkOrganizations)

                if updateLocations {
                    let locationIds = networkOrganizations
                        .flatMap { [$0.primaryLocation, $0.secondaryLocation] }
                        .compactMap { $0 }

                    if locationIds.isNotEmpty {
                        let locations = try await networkDataSource.getIncidentLocations(locationIds)
                        try await locationDao.saveLocations(locations.asRecordSource())
                    }
                }
            } catch {
                logger.logError(error)
            }
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

            try await saveOrganizations(networkOrganizations)
            let organizationIds = networkOrganizations.map { $0.id }
            return try incidentOrganizationDao.getOrganizations(organizationIds)
                .map { $0.asExternalModel() }
        } catch {
            logger.logError(error)
        }
        return []
    }

    func streamPrimarySecondaryAreas(_ organizationId: Int64) -> any Publisher<OrganizationLocationAreaBounds, Never> {
        incidentOrganizationDao.streamLocationIds(organizationId).map { locationIds in
            if let locationIds = locationIds {
                let ids = [
                    locationIds.primaryLocation,
                    locationIds.secondaryLocation
                ].compactMap { $0 }
                let bounds = self.locationDao.getLocations(ids)
                    .map { location in self.locationBoundsConverter.convert(location) }
                let primary = locationIds.primaryLocation == nil ? nil : bounds[0]
                let secondary = locationIds.secondaryLocation == nil ? nil : bounds[bounds.count - 1]
                return OrganizationLocationAreaBounds(primary, secondary)
            }

            return OrganizationLocationAreaBounds()
        }
    }

    func getMatchingOrganizations(_ q: String) -> [OrganizationIdName] {
        incidentOrganizationDao.getMatchingOrganizations(q)
    }
}
