import Foundation

public protocol NetworkRequestProvider {
    func apiUrl(_ path: String) -> URL
}

extension NetworkRequestProvider {
    var login: NetworkRequest {
        NetworkRequest(
            url: apiUrl("api-token-auth"),
            method: .post
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
