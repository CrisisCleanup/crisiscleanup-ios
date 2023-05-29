import Combine

public protocol AuthEventBus {
    var logouts: Published<Bool>.Publisher { get }
    var expiredTokens: Published<Bool>.Publisher { get }
    var credentialRequests: Published<Bool>.Publisher { get }
    var saveCredentialRequests: Published<(String, String)>.Publisher { get }
    var passwordCredentialResults: Published<PasswordCredentials>.Publisher { get }

    func onLogout()
    func onExpiredToken()
    func onPasswordRequest()
    func onSaveCredentials(emailAddress: String, password: String)
    func onPasswordCredentialsResult(credentials: PasswordCredentials)
}

public enum PasswordRequestCode {
    case success
    case fail
}
public struct PasswordCredentials {
    let emailAddress: String
    let password: String
    let resultCode: PasswordRequestCode
}
let emptyPasswordCredentials = PasswordCredentials(
    emailAddress: "",
    password: "",
    resultCode: .success
)

class CrisisCleanupAuthEventBus: AuthEventBus {
    @Published private var logoutStream = false
    lazy var logouts = $logoutStream

    @Published private var expiredTokenStream = false
    lazy var expiredTokens = $expiredTokenStream

    @Published private var credentialRequestStream = false
    lazy var credentialRequests = $credentialRequestStream

    @Published private var saveCredentialRequestStream = ("", "")
    lazy var saveCredentialRequests = $saveCredentialRequestStream

    @Published private var passwordCredentialResultStream = emptyPasswordCredentials
    lazy var passwordCredentialResults = $passwordCredentialResultStream

    func onLogout() {
        logoutStream = true
    }

    func onExpiredToken() {
        expiredTokenStream = true
    }

    func onPasswordRequest() {
        credentialRequestStream = true
    }

    func onSaveCredentials(emailAddress: String, password: String) {
        saveCredentialRequestStream = (emailAddress, password)
    }

    func onPasswordCredentialsResult(credentials: PasswordCredentials) {
        passwordCredentialResultStream = credentials
    }
}
