enum MainViewState {
    case loading
    case ready
}

struct MainViewData {
    let state: MainViewState
    let accountData: AccountData
    let showMainContent: Bool

    let isAuthenticated: Bool

    init(
        state: MainViewState = .loading,
        accountData: AccountData = emptyAccountData
    ) {
        self.state = state
        self.accountData = accountData
        isAuthenticated = accountData.hasAuthenticated()
        self.showMainContent = state == .ready && isAuthenticated
    }
}
