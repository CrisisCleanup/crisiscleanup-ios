import Foundation

public protocol CrisisCleanupNetworkDataSource {
    func getProfileData(_ accountId: Int64) async throws -> NetworkAccountProfileResult

    func getOrganizations(_ organizations: [Int64]) async throws -> [NetworkIncidentOrganization]

    func getStatuses() async throws -> NetworkWorkTypeStatusResult?

    func getIncidents(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident]

    func getIncidentsNoAuth(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident]

    func getIncidentsList(
        fields: [String],
        limit: Int,
        ordering: String
    ) async throws -> [NetworkIncidentShort]

    func getIncidentLocations(
        _ locationIds: [Int64]
    ) async throws -> [NetworkLocation]

    func getIncidentOrganizations(
        incidentId: Int64,
        fields: [String],
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
    ) async throws -> NetworkWorksitesPageResult

    func getWorksitesPageUpdatedAt(
        incidentId: Int64,
        pageCount: Int,
        updatedAt: Date,
        isPagingBackwards: Bool,
    ) async throws -> NetworkWorksitesPageResult

    func getWorksitesFlagsFormDataPage(
        incidentId: Int64,
        pageCount: Int,
        updatedAt: Date,
        isPagingBackwards: Bool,
    ) async throws -> NetworkFlagsFormDataResult

    func getWorksitesFlagsFormData(
        _ ids: Set<Int64>,
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

    func getLists(limit: Int, offset: Int?) async throws -> NetworkListsResult

    func getList(_ id: Int64) async throws -> NetworkList?

    func getLists(_ ids: [Int64]) async -> [NetworkList?]
}

extension CrisisCleanupNetworkDataSource {
    func getIncidents(
        _ fields: [String],
        _ after: Date?
    ) async throws -> [NetworkIncident] {
        try await getIncidents(fields: fields, limit: 250, ordering: "-start_at", after: after)
    }

    func getIncidentsNoAuth(
        _ fields: [String],
        _ after: Date?
    ) async throws -> [NetworkIncident] {
        try await getIncidentsNoAuth(fields: fields, limit: 30, ordering: "-start_at", after: after)
    }

    func getIncidentsList() async throws -> [NetworkIncidentShort] {
        try await getIncidentsList(
            fields: ["id", "name", "short_name", "incident_type"],
            limit: 250,
            ordering: "-start_at"
        )
    }

    func getWorksitesCount(_ incidentId: Int64) async throws -> Int {
        try await getWorksitesCount(incidentId, nil)
    }

    func getWorksitesPageBefore(
        _ incidentId: Int64,
        _ pageCount: Int,
        _ updatedBefore: Date,
    ) async throws -> NetworkWorksitesPageResult {
        try await getWorksitesPageUpdatedAt(
            incidentId: incidentId,
            pageCount: pageCount,
            updatedAt: updatedBefore,
            isPagingBackwards: true,
        )
    }

    func getWorksitesPageAfter(
        _ incidentId: Int64,
        _ pageCount: Int,
        _ updatedAfter: Date,
    ) async throws -> NetworkWorksitesPageResult {
        try await getWorksitesPageUpdatedAt(
            incidentId: incidentId,
            pageCount: pageCount,
            updatedAt: updatedAfter,
            isPagingBackwards: false,
        )
    }

    func getWorksitesFlagsFormDataPageBefore(
        _ incidentId: Int64,
        _ pageCount: Int,
        _ updatedBefore: Date,
    ) async throws -> NetworkFlagsFormDataResult {
        try await getWorksitesFlagsFormDataPage(
            incidentId: incidentId,
            pageCount: pageCount,
            updatedAt: updatedBefore,
            isPagingBackwards: true,
        )
    }

    func getWorksitesFlagsFormDataPageAfter(
        _ incidentId: Int64,
        _ pageCount: Int,
        _ updatedAfter: Date,
    ) async throws -> NetworkFlagsFormDataResult {
        try await getWorksitesFlagsFormDataPage(
            incidentId: incidentId,
            pageCount: pageCount,
            updatedAt: updatedAfter,
            isPagingBackwards: false,
        )
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
}
