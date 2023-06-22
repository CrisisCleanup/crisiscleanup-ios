import Combine

public protocol AuthEventBus {
    var logouts: any Publisher<Bool, Never> { get }
    var expiredTokens: any Publisher<Bool, Never> { get }

    func onLogout()
    func onExpiredToken()
}

class CrisisCleanupAuthEventBus: AuthEventBus {
    private let logoutSubject = PassthroughSubject<Bool, Never>()
    let logouts: any Publisher<Bool, Never>

    private let expiredTokenSubject = PassthroughSubject<Bool, Never>()
    let expiredTokens: any Publisher<Bool, Never>

    init() {
        logouts = logoutSubject.share()
        expiredTokens = expiredTokenSubject.share()
    }

    func onLogout() {
        logoutSubject.send(true)
    }

    func onExpiredToken() {
        expiredTokenSubject.send(true)
    }
}
