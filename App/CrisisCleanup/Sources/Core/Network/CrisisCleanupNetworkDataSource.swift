import Foundation

public protocol CrisisCleanupAuthApi {
    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult?
}

public protocol CrisisCleanupNetworkDataSource {
    func getStatuses() async throws -> NetworkWorkTypeStatusResult?

    func getIncidents(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident]

    func getIncidentLocations(
        locationIds: [Int64]
    ) async throws -> [NetworkLocation]

    func getIncidentOrganizations(
        incidentId: Int64,
        limit: Int,
        offset: Int
    ) async throws -> NetworkOrganizationsResult?

    func getIncident(
        id: Int64,
        fields: [String]
    ) async throws -> NetworkIncident?

    func getWorksitesCoreData(
        incidentId: Int64,
        limit: Int,
        offset: Int
    ) async throws -> [NetworkWorksiteCoreData]?

    func getWorksites(
        worksiteIds: [Int64]
    ) async throws -> [NetworkWorksiteFull]?

    func getWorksite(id: Int64) async throws -> NetworkWorksiteFull?

    func getWorksitesCount(
        incidentId: Int64,
        updatedAtAfter: Date?
    ) async throws -> Int

    func getWorksitesPage(
        incidentId: Int64,
        pageCount: Int,
        pageOffset: Int?,
        latitude: Double?,
        longitude: Double?,
        updatedAtAfter: Date?
    ) async throws -> [NetworkWorksitePage]

    func getLocationSearchWorksites(
        incidentId: Int64,
        q: String,
        limit: Int
    ) async throws -> [NetworkWorksiteLocationSearch]

    func getSearchWorksites(
        incidentId: Int64,
        q: String
    ) async throws -> [NetworkWorksiteShort]

    func getLanguages() async throws -> [NetworkLanguageDescription]

    func getLanguageTranslations(_ key: String) async throws -> NetworkLanguageTranslation?

    func getLocalizationCount(after: Date) async throws -> NetworkCountResult?

    func getWorkTypeRequests(id: Int64) async throws -> [NetworkWorkTypeRequest]

    func getNearbyOrganizations(
        latitude: Double,
        longitude: Double
    ) async throws -> [NetworkIncidentOrganization]
}
