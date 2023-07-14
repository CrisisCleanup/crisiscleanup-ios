import Combine

public protocol AuthEventBus {
    var logouts: any Publisher<Bool, Never> { get }
    var refreshedTokens: any Publisher<Bool, Never> { get }

    func onLogout()
    func onTokensRefreshed()
}

class CrisisCleanupAuthEventBus: AuthEventBus {
    private let logoutSubject = PassthroughSubject<Bool, Never>()
    let logouts: any Publisher<Bool, Never>

    private let refreshedTokensSubject = PassthroughSubject<Bool, Never>()
    let refreshedTokens: any Publisher<Bool, Never>

    init() {
        logouts = logoutSubject.share()
        refreshedTokens = refreshedTokensSubject.share()
    }

    func onLogout() {
        logoutSubject.send(true)
    }

    func onTokensRefreshed() {
        refreshedTokensSubject.send(true)
    }
}
