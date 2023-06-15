import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.translator) var translator
    let authenticateViewBuilder: AuthenticateViewBuilder
    let menuViewBuilder: MenuViewBuilder

    @State private var selectedTab = TopLevelDestination.menu
    var body: some View {
        switch viewModel.viewData.state {
        case .loading:
            Text("Splash")
        case .ready:
            if viewModel.viewData.showMainContent {
                NavigationView {
                    TabView(selection: $selectedTab) {
                        CasesView()
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
