import Foundation

public protocol NetworkRequestProvider {
    func apiUrl(_ path: String) -> URL
}

extension NetworkRequestProvider {
    var login: NetworkRequest {
        NetworkRequest(
            apiUrl("api-token-auth"),
            method: .post
        )
    }

    var languages: NetworkRequest {
        NetworkRequest(apiUrl("languages"))
    }

    var languageTranslations: NetworkRequest {
        NetworkRequest(
            apiUrl("languages")
        )
    }

    var localizationCount: NetworkRequest {
        NetworkRequest(apiUrl("localizations/count"))
    }

    var workTypeStatuses: NetworkRequest {
        NetworkRequest(apiUrl("statuses"))
    }

    var incidents: NetworkRequest {
        NetworkRequest(
            apiUrl("incidents"),
            addTokenHeader: true
        )
    }

    var incidentLocations: NetworkRequest {
        NetworkRequest(
            apiUrl("locations"),
            addTokenHeader: true
        )
    }

    var incident: NetworkRequest {
        NetworkRequest(
            apiUrl("incidents"),
            addTokenHeader: true
        )
    }

    var incidentOrganizations: NetworkRequest {
        NetworkRequest(
            apiUrl("incidents"),
            addTokenHeader: true
        )
    }

    var worksitesCoreData: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            addTokenHeader: true
        )
    }

    var worksitesLocationSearch: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            addTokenHeader: true
        )
    }

    var worksitesSearch: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites_all"),
            addTokenHeader: true
        )
    }

    var worksites: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            addTokenHeader: true
        )
    }

    var worksitesCount: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites/count"),
            addTokenHeader: true
        )
    }

    var worksitesPage: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites_page"),
            addTokenHeader: true
        )
    }

    var workTypeRequests: NetworkRequest {
        NetworkRequest(
            apiUrl("worksite_requests"),
            addTokenHeader: true
        )
    }

    var nearbyClaimedOrganizations: NetworkRequest {
        NetworkRequest(
            apiUrl("organizations"),
            addTokenHeader: true
        )
    }
}

class CrisisCleanupNetworkRequestProvider: NetworkRequestProvider {
    let baseUrl: URL

    init(_ appSettings: AppSettingsProvider) {
        baseUrl = try! appSettings.apiBaseUrl.asURL()
    }

    func apiUrl(_ path: String) -> URL {
        return baseUrl.appendingPathComponent(path)
    }
}
