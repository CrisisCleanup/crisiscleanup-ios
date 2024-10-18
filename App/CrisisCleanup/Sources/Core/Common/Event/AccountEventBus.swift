import Combine

public protocol AccountEventBus {
    var logouts: any Publisher<Bool, Never> { get }
    var refreshedTokens: any Publisher<Bool, Never> { get }
    var inactiveOrganizations: any Publisher<Int64, Never> { get }

    func onLogout()
    func onTokensRefreshed()
    func onAccountInactiveOrganizations(_ accountId: Int64)
    func clearAccountInactiveOrganization()
}

class CrisisCleanupAccountEventBus: AccountEventBus {
    private let logoutSubject = PassthroughSubject<Bool, Never>()
    let logouts: any Publisher<Bool, Never>

    private let refreshedTokensSubject = PassthroughSubject<Bool, Never>()
    let refreshedTokens: any Publisher<Bool, Never>

    private let inactiveOrganizationsSubject = PassthroughSubject<Int64, Never>()
    let inactiveOrganizations: any Publisher<Int64, Never>

    init() {
        logouts = logoutSubject.share()
        refreshedTokens = refreshedTokensSubject.share()
        inactiveOrganizations = inactiveOrganizationsSubject
    }

    func onLogout() {
        logoutSubject.send(true)
    }

    func onTokensRefreshed() {
        refreshedTokensSubject.send(true)
    }

    func onAccountInactiveOrganizations(_ accountId: Int64) {
        inactiveOrganizationsSubject.send(accountId)
    }

    func clearAccountInactiveOrganization() {
        onAccountInactiveOrganizations(0)
    }
}
