import Foundation

public protocol CrisisCleanupAuthApi {
    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult?

    func oauthLogin(_ email: String, _ password: String) async throws -> NetworkOAuthResult?

    func refreshTokens(_ refreshToken: String) async throws -> NetworkOAuthResult?
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
        _ locationIds: [Int64]
    ) async throws -> [NetworkLocation]

    func getIncidentOrganizations(
        incidentId: Int64,
        limit: Int,
        offset: Int
    ) async throws -> NetworkOrganizationsResult?

    func getIncident(
        _ id: Int64,
        _ fields: [String]
    ) async throws -> NetworkIncident?

    func getWorksitesCoreData(
        incidentId: Int64,
        limit: Int,
        offset: Int
    ) async throws -> [NetworkWorksiteCoreData]?

    func getWorksites(_ worksiteIds: [Int64]) async throws -> [NetworkWorksiteFull]?

    func getWorksite(_ id: Int64) async throws -> NetworkWorksiteFull?

    func getWorksitesCount(
        _ incidentId: Int64,
        _ updatedAtAfter: Date?
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
        _ incidentId: Int64,
        _ q: String,
        _ limit: Int
    ) async throws -> [NetworkWorksiteLocationSearch]

    func getSearchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async throws -> [NetworkWorksiteShort]

    func getLanguages() async throws -> [NetworkLanguageDescription]

    func getLanguageTranslations(_ key: String) async throws -> NetworkLanguageTranslation?

    func getLocalizationCount(_ after: Date) async throws -> NetworkCountResult?

    func getWorkTypeRequests(_ id: Int64) async throws -> [NetworkWorkTypeRequest]

    func getNearbyOrganizations(
        _ latitude: Double,
        _ longitude: Double
    ) async throws -> [NetworkIncidentOrganization]
}

extension CrisisCleanupNetworkDataSource {
    func getIncidents(
        _ fields: [String],
        _ after: Date?
    ) async throws -> [NetworkIncident] {
        return try await getIncidents(fields: fields, limit: 250, ordering: "-start_at", after: after)
    }
}
