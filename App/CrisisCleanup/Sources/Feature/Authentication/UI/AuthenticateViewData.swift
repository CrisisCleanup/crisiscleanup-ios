enum AuthenticateViewState {
    case loading
    case ready
}

struct AuthenticateViewData {
    let state: AuthenticateViewState
    let accountData: AccountData

    let hasAuthenticated: Bool
    let isAccountValid: Bool

    init(
        state: AuthenticateViewState = .loading,
        accountData: AccountData = emptyAccountData
    ) {
        self.state = state
        self.accountData = accountData

        hasAuthenticated = accountData.hasAuthenticated
        isAccountValid = accountData.areTokensValid
    }
}
