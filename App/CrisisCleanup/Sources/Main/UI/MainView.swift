import SwiftUI

struct MainView: View {
    @Environment(\.translator) var translator

    @ObservedObject var viewModel: MainViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder

    @State private var selectedTab = TopLevelDestination.cases
    var body: some View {
        switch viewModel.viewData.state {
        case .loading:
            // TODO: Show actual splash screen (or loading animation)
            Text("Splash")
        case .ready:
            if viewModel.viewData.showMainContent {
                NavigationStack {
                    TabView(selection: $selectedTab) {
                        casesViewBuilder.casesView
                            .navTabItem(.cases, viewModel.translator)
                            .tag(TopLevelDestination.cases)
                        menuViewBuilder.menuView
                            .navTabItem(.menu, viewModel.translator)
                            .tag(TopLevelDestination.menu)
                    }
                }
                .environment(\.translator, viewModel.translator)
            } else {
                authenticateViewBuilder.authenticateView
                    .environment(\.translator, viewModel.translator)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            }
        }
    }
}
