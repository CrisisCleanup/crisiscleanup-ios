import Foundation

public protocol NetworkRequestProvider {
    func apiUrl(_ path: String) -> URL

    func appSupportApiUrl(_ path: String) -> URL?
}

extension NetworkRequestProvider {
    var login: NetworkRequest {
        NetworkRequest(
            apiUrl("api-token-auth"),
            method: .post
        )
    }

    var oauthLogin: NetworkRequest {
        NetworkRequest(
            apiUrl("api-mobile-auth"),
            method: .post
        )
    }

    var magicLinkCodeAuth: NetworkRequest {
        NetworkRequest(
            apiUrl("magic_link"),
            method: .post,
            clearCookies: true
        )
    }

    var verifyOneTimePassword: NetworkRequest {
        NetworkRequest(
            apiUrl("otp/verify"),
            method: .post,
            clearCookies: true
        )
    }

    var oneTimePasswordAuth: NetworkRequest {
        NetworkRequest(
            apiUrl("otp/generate_token"),
            method: .post,
            clearCookies: true
        )
    }

    var refreshAccountTokens: NetworkRequest {
        NetworkRequest(
            apiUrl("api-mobile-refresh-token"),
            method: .post,
            clearCookies: true
        )
    }

    var accountProfile: NetworkRequest {
        NetworkRequest(
            apiUrl("users/me"),
            addTokenHeader: true
        )
    }

    var accountProfileNoToken: NetworkRequest {
        NetworkRequest(
            apiUrl("users/me"),
            clearCookies: true
        )
    }

    var organizations: NetworkRequest {
        NetworkRequest(
            apiUrl("organizations"),
            addTokenHeader: true
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

    var worksitesFlagsFormData: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites_data_flags"),
            addTokenHeader: true
        )
    }

    var workTypeRequests: NetworkRequest {
        NetworkRequest(
            apiUrl("worksite_requests"),
            addTokenHeader: true
        )
    }

    var users: NetworkRequest {
        NetworkRequest(
            apiUrl("users"),
            addTokenHeader: true
        )
    }

    var caseHistory: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            addTokenHeader: true
        )
    }

    var redeployRequests: NetworkRequest {
        NetworkRequest(
            apiUrl("incident_requests"),
            addTokenHeader: true
        )
    }

    var lists: NetworkRequest {
        NetworkRequest(
            apiUrl("lists"),
            addTokenHeader: true
        )
    }

    var list: NetworkRequest {
        NetworkRequest(
            apiUrl("lists"),
            addTokenHeader: true
        )
    }

    // MARK: Write requests

    var newWorksite: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var updateWorksite: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .put,
            addTokenHeader: true
        )
    }

    var favorite: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var unfavorite: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .delete,
            addTokenHeader: true
        )
    }

    var addFlag: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var deleteFlag: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .delete,
            addTokenHeader: true
        )
    }

    var addNote: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var updateWorkTypeStatus: NetworkRequest {
        NetworkRequest(
            apiUrl("worksite_work_types"),
            method: .patch,
            addTokenHeader: true
        )
    }

    var claimWorkTypes: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var unclaimWorkTypes: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var requestWorkTypes: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var releaseWorkTypes: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var deleteFile: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .delete,
            addTokenHeader: true
        )
    }

    var startFileUpload: NetworkRequest {
        NetworkRequest(
            apiUrl("files"),
            method: .post,
            addTokenHeader: true
        )
    }

    var addUploadedFile: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    var shareWorksite: NetworkRequest {
        NetworkRequest(
            apiUrl("worksites"),
            method: .post,
            addTokenHeader: true
        )
    }

    // MARK: Version support

    var minAppVersionSupport: NetworkRequest? {
        if let url = appSupportApiUrl("min-supported-version/ios") {
            return NetworkRequest(url)
        }
        return nil
    }

    var testMinAppVersionSupport: NetworkRequest? {
        if let url = appSupportApiUrl("min-supported-version/test/ios") {
            return NetworkRequest(url)
        }
        return nil
    }

    // MARK: Account requests

    var initiateMagicLink: NetworkRequest {
        NetworkRequest(
            apiUrl("magic_link"),
            method: .post,
            clearCookies: true
        )
    }

    var initiatePhoneLogin: NetworkRequest {
        NetworkRequest(
            apiUrl("otp"),
            method: .post,
            clearCookies: true
        )
    }

    var initiatePasswordReset: NetworkRequest {
        NetworkRequest(
            apiUrl("password_reset_requests"),
            method: .post
        )
    }

    var resetPassword: NetworkRequest {
        NetworkRequest(
            apiUrl("password_reset_requests"),
            method: .post
        )
    }

    var resetPasswordStatus: NetworkRequest {
        NetworkRequest(
            apiUrl("password_reset_requests")
        )
    }

    var acceptTerms: NetworkRequest {
        NetworkRequest(
            apiUrl("users"),
            method: .patch,
            addTokenHeader: true
        )
    }

    var requestRedeploy: NetworkRequest {
        NetworkRequest(
            apiUrl("incident_requests"),
            method: .post,
            addTokenHeader: true
        )
    }

    // MARK: Register

    var requestInvitation: NetworkRequest {
        NetworkRequest(
            apiUrl("invitation_requests"),
            method: .post
        )
    }

    var invitationInfo: NetworkRequest {
        NetworkRequest(
            apiUrl("invitations")
        )
    }

    var persistentInvitationInfo: NetworkRequest {
        NetworkRequest(
            apiUrl("persistent_invitations")
        )
    }

    var noAuthUser: NetworkRequest {
        NetworkRequest(
            apiUrl("users"),
            clearCookies: true
        )
    }

    var noAuthOrganization: NetworkRequest {
        NetworkRequest(
            apiUrl("organizations"),
            clearCookies: true
        )
    }

    var acceptInvitationFromCode: NetworkRequest {
        NetworkRequest(
            apiUrl("invitations/accept"),
            method: .post
        )
    }

    var createPersistentInvitation: NetworkRequest {
        NetworkRequest(
            apiUrl("persistent_invitations"),
            method: .post,
            addTokenHeader: true
        )
    }

    var acceptPersistentInvitation: NetworkRequest {
        NetworkRequest(
            apiUrl("persistent_invitations/accept"),
            method: .post
        )
    }

    var inviteToOrganization: NetworkRequest {
        NetworkRequest(
            apiUrl("invitations"),
            method: .post,
            addTokenHeader: true
        )
    }

    var registerOrganization: NetworkRequest {
        NetworkRequest(
            apiUrl("organizations"),
            method: .post,
            addTokenHeader: true
        )
    }
}

class CrisisCleanupNetworkRequestProvider: NetworkRequestProvider {
    let baseUrl: URL
    let appSupportBaseUrl: URL?

    init(_ appSettings: AppSettingsProvider) {
        baseUrl = try! appSettings.apiBaseUrl.asURL()
        appSupportBaseUrl = try? appSettings.appSupportApiBaseUrl.asURL()
    }

    func apiUrl(_ path: String) -> URL {
        baseUrl.appendingPathComponent(path)
    }

    func appSupportApiUrl(_ path: String) -> URL? {
        appSupportBaseUrl?.appendingPathComponent(path)
    }
}
