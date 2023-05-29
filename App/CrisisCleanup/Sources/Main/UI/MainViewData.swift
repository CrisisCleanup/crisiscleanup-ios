enum MainViewState {
    case loading
    case ready
}

struct MainViewData {
    let state: MainViewState
    let isAuthenticated: Bool

    init(
        state: MainViewState = .loading,
        isAuthenticated: Bool = false
    ) {
        self.state = state
        self.isAuthenticated = isAuthenticated
    }
}
