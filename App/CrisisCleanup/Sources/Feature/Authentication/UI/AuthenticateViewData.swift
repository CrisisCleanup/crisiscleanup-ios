enum AuthenticateViewState {
    case loading
    case ready
}

struct AuthenticateViewData {
    let state: AuthenticateViewState
    let accountData: AccountData

    var hasAccessToken: Bool {
        get {
            return accountData.accessToken.isNotBlank
        }
    }

    var isTokenInvalid: Bool {
        get {
            return accountData.isTokenInvalid
        }
    }

    init(
        state: AuthenticateViewState = .loading,
        accountData: AccountData = emptyAccountData
    ) {
        self.state = state
        self.accountData = accountData
    }
}
