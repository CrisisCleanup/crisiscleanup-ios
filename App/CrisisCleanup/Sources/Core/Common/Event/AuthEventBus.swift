import Combine

public protocol AuthEventBus {
    var logouts: Published<Bool>.Publisher { get }
    var expiredTokens: Published<Bool>.Publisher { get }

    func onLogout()
    func onExpiredToken()
}

class CrisisCleanupAuthEventBus: AuthEventBus {
    @Published private var logoutStream = false
    lazy private(set) var logouts = $logoutStream

    @Published private var expiredTokenStream = false
    lazy private(set) var expiredTokens = $expiredTokenStream

    func onLogout() {
        logoutStream = true
    }

    func onExpiredToken() {
        expiredTokenStream = true
    }
}
