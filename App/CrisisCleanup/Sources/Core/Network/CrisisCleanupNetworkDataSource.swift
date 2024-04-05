import Foundation

public protocol CrisisCleanupNetworkDataSource {
    func getProfileData() async throws -> NetworkAccountProfileResult

    func getOrganizations(_ organizations: [Int64]) async throws -> [NetworkIncidentOrganization]

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

    func getWorksitesFlagsFormDataPage(
        incidentId: Int64,
        pageCount: Int,
        pageOffset: Int?,
        updatedAtAfter: Date?
    ) async throws -> [NetworkFlagsFormData]

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

    func searchUsers(
        _ q: String,
        _ organization: Int64,
        limit: Int
    ) async throws -> [NetworkPersonContact]

    func getCaseHistory(
        _ worksiteId: Int64
    ) async throws -> [NetworkCaseHistoryEvent]

    func getUsers(
        _ userIds: [Int64]
    ) async throws -> [NetworkPersonContact]

    func getAppSupportInfo(
        _ isTest: Bool
    ) async -> NetworkAppSupportInfo?

    func searchOrganizations(_ q: String) async -> [NetworkOrganizationShort]

    func getProfile(_ accessToken: String) async -> NetworkUserProfile?

    func getRequestRedeployIncidentIds() async throws -> Set<Int64>
}

extension CrisisCleanupNetworkDataSource {
    func getIncidents(
        _ fields: [String],
        _ after: Date?
    ) async throws -> [NetworkIncident] {
        return try await getIncidents(fields: fields, limit: 250, ordering: "-start_at", after: after)
    }

    func searchUsers(
        _ q: String,
        _ organization: Int64
    ) async throws -> [NetworkPersonContact] {
        try await searchUsers(q, organization, limit: 10)
    }

    func getAppSupportInfo() async -> NetworkAppSupportInfo? {
        await getAppSupportInfo(false)
    }

    func getWorksitesFlagsFormDataPage(
        incidentId: Int64,
        pageCount: Int
    ) async throws -> [NetworkFlagsFormData] {
        try await getWorksitesFlagsFormDataPage(
            incidentId: incidentId,
            pageCount: pageCount,
            pageOffset: nil,
            updatedAtAfter: nil
        )
    }
}
