import Foundation

class DataApiClient : CrisisCleanupNetworkDataSource {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let jsonDecoder: JSONDecoder
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
        appEnv: AppEnv,
        networkRequestProvider: NetworkRequestProvider
    ) {
        self.networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider

        jsonDecoder = JsonDecoderFactory().decoder()
        dateFormatter = ISO8601DateFormatter()

        worksiteCoreDataFieldsQ = worksiteCoreDataFields.commaJoined
        locationSearchFieldsQ = locationSearchFields.commaJoined

        networkError = GenericError("Network error")
    }

    func getStatuses() async throws -> NetworkWorkTypeStatusResult? {
        let request = requestProvider.workTypeStatuses
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorkTypeStatusResult.self
        ).value
    }

    func getIncidents(
        fields: [String],
        limit: Int,
        ordering: String,
        after: Date?
    ) async throws -> [NetworkIncident] {
        let request = requestProvider.incidents.addQueryItems(
            "fields", fields.commaJoined,
            "limit", String(limit),
            "ordering", ordering,
            "start_at__gt", after == nil ? nil : dateFormatter.string(from: after!)
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkIncidentsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? [NetworkIncident]()
        }
        throw response.error ?? networkError
    }

    func getIncidentLocations(_ locationIds: [Int64]) async throws -> [NetworkLocation] {
        let request = requestProvider.incidentLocations.addQueryItems(
            "id__in", locationIds.map{String($0)}.commaJoined,
            "limit", String(locationIds.count)
        )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkLocationsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? [NetworkLocation]()
        }
        throw response.error ?? networkError
    }

    func getIncidentOrganizations(incidentId: Int64, limit: Int, offset: Int) async throws -> NetworkOrganizationsResult? {
        let request = requestProvider.incidentOrganizations
            .addPaths(String(incidentId), "organizations")
            .addQueryItems(
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
                "id__in", worksiteIds.map { String($0) }.commaJoined
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesFullResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? [NetworkWorksiteFull]()
        }
        throw response.error ?? networkError
    }

    func getWorksite(_ id: Int64) async throws -> NetworkWorksiteFull? {
        return try await getWorksites([id])?.firstOrNil
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

    func getWorksitesPage(
        incidentId: Int64,
        pageCount: Int,
        pageOffset: Int?,
        latitude: Double?,
        longitude: Double?,
        updatedAtAfter: Date?
    ) async throws -> [NetworkWorksitePage] {
        let page = (pageOffset ?? 0) <= 1 ? nil : String(pageOffset!)
        let centerCoordinates: String? = latitude == nil && longitude == nil ? nil : "\(latitude!),\(longitude!)"
        let request = requestProvider.worksitesPage
            .addQueryItems(
                "incident", String(incidentId),
                "limit", String(pageCount),
                "page", page,
                "center_coordinates", centerCoordinates,
                "updated_at__gt", updatedAtAfter == nil ? nil : dateFormatter.string(from: updatedAtAfter!)
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksitesPageResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? [NetworkWorksitePage]()
        }
        throw response.error ?? networkError
    }

    func getLocationSearchWorksites(incidentId: Int64, q: String, limit: Int) async throws -> [NetworkWorksiteLocationSearch] {
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
            return result.results ?? [NetworkWorksiteLocationSearch]()
        }
        throw response.error ?? networkError
    }

    func getSearchWorksites(_ incidentId: Int64, _ q: String) async throws -> [NetworkWorksiteShort] {
        let request = requestProvider.worksitesLocationSearch
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
            return result.results ?? [NetworkWorksiteShort]()
        }
        throw response.error ?? networkError
    }

    func getLanguages() async throws -> [NetworkLanguageDescription] {
        return await networkClient.callbackContinue(
            requestConvertible: requestProvider.languages,
            type: NetworkLanguagesResult.self
        ).value?.results ?? [NetworkLanguageDescription]()
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
            return result.results ?? [NetworkWorkTypeRequest]()
        }
        throw response.error ?? networkError
    }

    func getNearbyOrganizations(_ latitude: Double, _ longitude: Double) async throws -> [NetworkIncidentOrganization] {
        let request = requestProvider.nearbyClaimedOrganizations
            .addQueryItems(
                "nearby_claimed", "\(longitude),\(latitude)"
            )
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationsResult.self
        )
        if let result = response.value {
            try result.errors?.tryThrowException()
            return result.results ?? [NetworkIncidentOrganization]()
        }
        throw response.error ?? networkError
    }
}
