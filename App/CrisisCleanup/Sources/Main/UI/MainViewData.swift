enum MainViewState {
    case loading
    case ready
    case unsupportedBuild
}

struct MainViewData {
    let state: MainViewState
    let accountData: AccountData
    let showMainContent: Bool

    let isAuthenticated: Bool
    let areTokensValid: Bool
    let hasAcceptedTerms: Bool

    init(
        state: MainViewState = .loading,
        accountData: AccountData = emptyAccountData
    ) {
        self.state = state
        self.accountData = accountData
        isAuthenticated = accountData.hasAuthenticated
        areTokensValid = accountData.areTokensValid
        self.showMainContent = state == .ready && isAuthenticated
        hasAcceptedTerms = accountData.hasAcceptedTerms
    }
}
