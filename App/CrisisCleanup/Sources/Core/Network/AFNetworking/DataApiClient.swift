import Foundation

class DataApiClient : CrisisCleanupNetworkDataSource {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let dateFormatter: ISO8601DateFormatter

    private let networkError: Error

    private let worksiteCoreDataFields = [
        "id",
        "incident",
        "name",
        "case_number",
        "location",
        "address",
        "postal_code",
        "city",
        "county",
        "state",
        "phone1",
        "phone2",
        "email",
        "form_data",
        "flags",
        "notes",
        "work_types",
        "favorite",
        "what3words",
        "pluscode",
        "svi",
        "auto_contact_frequency_t",
        "reported_by",
        "updated_at",
    ]
    private let worksiteCoreDataFieldsQ: String

    private let locationSearchFields = [
        "id",
        "name",
        "case_number",
        "address",
        "postal_code",
        "city",
        "state",
        "incident",
        "location",
        "key_work_type",
    ]
    private let locationSearchFieldsQ: String

    init(
        networkRequestProvider: NetworkRequestProvider,
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        accountEventBus: AccountEventBus,
        appEnv: AppEnv
    ) {
        let jsonDecoder = JsonDecoderFactory().multiDateDecoder()
        self.networkClient = AFNetworkingClient(
            appEnv,
            interceptor: AccessTokenInterceptor(
                accountDataRepository: accountDataRepository,
                authApiClient: authApiClient,
                accountEventBus: accountEventBus
            ),
            jsonDecoder: jsonDecoder
        )
        requestProvider = networkRequestProvider

        dateFormatter = ISO8601DateFormatter()

        worksiteCoreDataFieldsQ = worksiteCoreDataFields.commaJoined
        locationSearchFieldsQ = locationSearchFields.commaJoined

        networkError = GenericError("Network error")
    }

    func getProfileData(_ accountId: Int64) async throws -> NetworkAccountProfileResult {
        let request = requestProvider.accountProfile.addPaths("\(accountId)")
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkAccountProfileResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result
        }
        throw response.error ?? networkError
    }

    func getOrganizations(_ organizations: [Int64]) async throws -> [NetworkIncidentOrganization] {
        let request = requestProvider.organizations.addQueryItems(
            "id__in", organizations.commaJoined
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getStatuses() async throws -> NetworkWorkTypeStatusResult? {
        let request = requestProvider.workTypeStatuses
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorkTypeStatusResult.self
        ).value
    }

    private func getIncidents(
        networkRequest: NetworkRequest,
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident] {
        let request = networkRequest.addQueryItems(
            "fields", fields.commaJoined,
            "limit", String(limit),
            "sort", ordering,
            "start_at__gt", after == nil ? nil : dateFormatter.string(from: after!)
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkIncidentsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getIncidents(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident] {
        try await getIncidents(
            networkRequest: requestProvider.incidents,
            fields: fields,
            limit: limit,
            ordering: ordering,
            after: after
        )
    }

    func getIncidentsNoAuth(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident] {
        try await getIncidents(
            networkRequest: requestProvider.incidentsNoAuth,
            fields: fields,
            limit: limit,
            ordering: ordering,
            after: after
        )
    }

    func getIncidentsList(
        fields: [String],
        limit: Int,
        ordering: String
    ) async throws -> [NetworkIncidentShort] {
        let request = requestProvider.incidentsList.addQueryItems(
            "fields", fields.commaJoined,
            "limit", String(limit),
            "sort", ordering
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkIncidentsListResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getIncidentLocations(_ locationIds: [Int64]) async throws -> [NetworkLocation] {
        let request = requestProvider.incidentLocations.addQueryItems(
            "id__in", locationIds.commaJoined,
            "limit", String(locationIds.count)
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkLocationsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getIncidentOrganizations(
        incidentId: Int64,
        fields: [String],
        limit: Int,
        offset: Int
    ) async throws -> NetworkOrganizationsResult? {
        let request = requestProvider.incidentOrganizations
            .addQueryItems(
                "incident", String(incidentId),
                "fields", fields.joined(separator: ","),
                "limit", String(limit),
                "offset", String(offset)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationsResult.self
        )
        if let result=response.value {
            try result.errors?.tryThrowException()
            return result
        }
        throw response.error ?? networkError
    }

    func getIncident(_ id: Int64, _ fields: [String]) async throws -> NetworkIncident? {
        let request = requestProvider.incident
            .addPaths(String(id))
            .addQueryItems(
                "fields", fields.commaJoined
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkIncidentResult.self,
            wrapResponseKey: "incident"
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.incident
        }
        throw response.error ?? networkError
    }

    func getWorksitesCoreData(incidentId: Int64, limit: Int, offset: Int) async throws -> [NetworkWorksiteCoreData]? {
        let request = requestProvider.worksitesCoreData
            .addQueryItems(
                "incident", String(incidentId),
                "limit", String(limit),
                "offset", String(offset),
                "fields", worksiteCoreDataFieldsQ
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesCoreDataResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results
        }
        throw response.error ?? networkError
    }

    func getWorksites(_ worksiteIds: [Int64]) async throws -> [NetworkWorksiteFull]? {
        let request = requestProvider.worksites
            .addQueryItems(
                "id__in", worksiteIds.commaJoined
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesFullResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getWorksite(_ id: Int64) async throws -> NetworkWorksiteFull? {
        let request = requestProvider.worksite
            .addQueryItems(
                "id__in", "\(id)"
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesFullResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results?.firstOrNil
        }
        return nil
    }

    func getWorksitesCount(
        _ incidentId: Int64,
        _ updatedAtAfter: Date? = nil
    ) async throws -> Int {
        let request = requestProvider.worksitesCount
            .addQueryItems(
                "incident", String(incidentId),
                "updated_at__gt", updatedAtAfter == nil ? nil : dateFormatter.string(from: updatedAtAfter!)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkCountResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.count ?? 0
        }
        throw response.error ?? networkError
    }

    private func processWorksitesPage(_ request: NetworkRequest) async throws -> NetworkWorksitesPageResult {
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesPageResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result
        }
        throw response.error ?? networkError
    }

    func getWorksitesPage(
        incidentId: Int64,
        pageCount: Int,
        pageOffset: Int?,
        latitude: Double?,
        longitude: Double?,
        updatedAtAfter: Date?
    ) async throws -> NetworkWorksitesPageResult {
        let page = (pageOffset ?? 0) <= 1 ? nil : String(pageOffset!)
        let centerCoordinates: String? = latitude == nil && longitude == nil ? nil : "\(longitude!),\(latitude!)"
        let request = requestProvider.worksitesPage
            .addQueryItems(
                "incident", String(incidentId),
                "limit", String(pageCount),
                "page", page,
                "center_coordinates", centerCoordinates,
                "updated_at__gt", updatedAtAfter == nil ? nil : dateFormatter.string(from: updatedAtAfter!)
            )
        return try await processWorksitesPage(request)
    }

    func getWorksitesPageUpdatedAt(
        incidentId: Int64,
        pageCount: Int,
        updatedAt: Date,
        isPagingBackwards: Bool,
        offset: Int,
    ) async throws -> NetworkWorksitesPageResult {
        let updatedAtKey = isPagingBackwards ? "updated_at__lt" : "updated_at__gt"
        let sortValue = isPagingBackwards ? "-updated_at" : "updated_at"
        let request = requestProvider.worksitesPage
            .addQueryItems(
                "incident", String(incidentId),
                "limit", String(pageCount),
                "offset", String(offset),
                updatedAtKey, dateFormatter.string(from: updatedAt),
                "sort", sortValue,
            )
        return try await processWorksitesPage(request)
    }

    private func processWorksitesFlagsFormData(_ request: NetworkRequest) async throws -> NetworkFlagsFormDataResult {
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkFlagsFormDataResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result
        }
        throw response.error ?? networkError
    }

    func getWorksitesFlagsFormDataPage(
        incidentId: Int64,
        pageCount: Int,
        updatedAt: Date,
        isPagingBackwards: Bool,
        offset: Int,
    ) async throws -> NetworkFlagsFormDataResult {
        let updatedAtKey = isPagingBackwards ? "updated_at__lt" : "updated_at__gt"
        let sortValue = isPagingBackwards ? "-updated_at" : "updated_at"
        let request = requestProvider.worksitesFlagsFormData
            .addQueryItems(
                "incident", String(incidentId),
                "limit", String(pageCount),
                "offset", String(offset),
                updatedAtKey, dateFormatter.string(from: updatedAt),
                "sort", sortValue,
            )
        return try await processWorksitesFlagsFormData(request)
    }

    func getWorksitesFlagsFormData(_ ids: Set<Int64>) async throws -> [NetworkFlagsFormData] {
        let request = requestProvider.worksitesFlagsFormData
            .addQueryItems(
                "id__in", ids
                    .map { "\($0)"}
                    .joined(separator: ",")
            )
        return try await processWorksitesFlagsFormData(request).data ?? []
    }

    func getLocationSearchWorksites(_ incidentId: Int64, _ q: String, _ limit: Int) async throws -> [NetworkWorksiteLocationSearch] {
        let request = requestProvider.worksitesLocationSearch
            .addQueryItems(
                "incident", String(incidentId),
                "fields", locationSearchFieldsQ,
                "search", q,
                "limit", String(limit)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksiteLocationSearchResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getSearchWorksites(_ incidentId: Int64, _ q: String) async throws -> [NetworkWorksiteShort] {
        let request = requestProvider.worksitesSearch
            .addQueryItems(
                "incident", String(incidentId),
                "search", q
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesShortResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getLanguages() async throws -> [NetworkLanguageDescription] {
        return await networkClient.callbackContinue(
            requestConvertible: requestProvider.languages,
            type: NetworkLanguagesResult.self
        ).value?.results ?? []
    }

    func getLanguageTranslations(_ key: String) async throws -> NetworkLanguageTranslation? {
        let request = requestProvider.languageTranslations
            .addPaths(key)
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkLanguageTranslationResult.self,
            wrapResponseKey: "translation"
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.translation
        }
        throw response.error ?? networkError
    }

    func getLocalizationCount(_ after: Date) async throws -> NetworkCountResult? {
        let request = requestProvider.localizationCount
            .addQueryItems(
                "updated_at__gt", dateFormatter.string(from: after)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkCountResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result
        }
        throw response.error ?? networkError
    }

    func getWorkTypeRequests(_ id: Int64) async throws -> [NetworkWorkTypeRequest] {
        let request = requestProvider.localizationCount
            .addQueryItems(
                "worksite_work_type__worksite", String(id)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorkTypeRequestResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func getNearbyOrganizations(_ latitude: Double, _ longitude: Double) async throws -> [NetworkIncidentOrganization] {
        let request = requestProvider.organizations
            .addQueryItems(
                "nearby_claimed", "\(longitude),\(latitude)"
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    private func processUsersRequest(_ request: NetworkRequest) async throws -> [NetworkPersonContact] {
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkUsersResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? []
        }
        throw response.error ?? networkError
    }

    func searchUsers(
        _ q: String,
        _ organization: Int64,
        limit: Int
    ) async throws -> [NetworkPersonContact] {
        let request = requestProvider.users
            .addQueryItems(
                "search", q,
                "organization", "\(organization)",
                "limit", "\(limit)"
            )
        return try await processUsersRequest(request)
    }

    func getCaseHistory(_ worksiteId: Int64) async throws -> [NetworkCaseHistoryEvent] {
        let request = requestProvider.caseHistory
            .addPaths(String(worksiteId), "history")
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkCaseHistoryResult.self,
            wrapResponseKey: "events"
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.events ?? []
        }
        throw response.error ?? networkError
    }

    func getUsers(_ userIds: [Int64]) async throws -> [NetworkPersonContact] {
        let request = requestProvider.users
            .addQueryItems(
                "id__in", userIds.commaJoined
            )
        return try await processUsersRequest(request)
    }

    func getAppSupportInfo(_ isTest: Bool) async -> NetworkAppSupportInfo? {
        let request = isTest
        ? requestProvider.testMinAppVersionSupport
        : requestProvider.minAppVersionSupport
        if let req = request {
            return await networkClient.callbackContinue(
                requestConvertible: req,
                type: NetworkAppSupportInfo.self
            ).value
        }
        return nil
    }

    func searchOrganizations(_ q: String) async -> [NetworkOrganizationShort] {
        let request = requestProvider.organizations
            .addQueryItems("search", q)
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationsSearchResult.self
        ).value?.results ?? []
    }

    func getProfile(_ accessToken: String) async -> NetworkUserProfile? {
        let request = requestProvider.accountProfileNoToken
            .addHeaders(["Authorization": "Bearer \(accessToken)"])
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkUserProfile.self
        ).value
    }

    func getRequestRedeployIncidentIds() async throws -> Set<Int64> {
        let request = requestProvider.redeployRequests
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkRedeployRequestsResult.self
        )

        if let result = response.value {
            try result.errors?.tryThrowException()
            if let incidentResults = result.results {
                return Set(incidentResults.map { $0.incident} )
            }
        }

        throw response.error ?? networkError
    }

    func getLists(limit: Int, offset: Int?) async throws -> NetworkListsResult {
        let qOffset = offset == nil ? nil : String(offset!)
        let request = requestProvider.lists
            .addQueryItems(
                "limit", String(limit),
                "offset", qOffset
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkListsResult.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func getList(_ id: Int64) async throws -> NetworkList? {
        let request = requestProvider.list
            .addPaths(String(id))
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkListResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.list
        }
        throw response.error ?? networkError
    }

    func getLists(_ ids: [Int64]) async -> [NetworkList?] {
        var networkLists = [NetworkList?]()
        for id in ids {
            var list: NetworkList? = nil
            do {
                list = try await getList(id)
            } catch {
            }
            networkLists.append(list)
        }
        return networkLists
    }

    func getWorksiteChanges(_ after: Date) async throws -> [NetworkWorksiteChange] {
        let request = requestProvider.worksiteChanges.addQueryItems(
                "since", dateFormatter.string(from: after)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksiteChangeResult.self,
            wrapResponseKey: "changes"
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            if let errorMessage = result.error {
                throw GenericError(errorMessage)
            }
            return result.changes ?? []
        }
        throw response.error ?? networkError
    }

    func getClaimThresholds() async throws -> NetworkClaimThreshold {
        let request = requestProvider.currentPortalConfig
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPortalConfig.self
        )
        if let result = response.value {
            return result.attr
        }
        throw response.error ?? networkError
    }
}

extension Array where Element == Int64 {
    fileprivate var commaJoined: String {
        map { String($0) }.commaJoined
    }
}
