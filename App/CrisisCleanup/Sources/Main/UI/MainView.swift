import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
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
                            .navTabItem(destination: .cases)
                            .tag(TopLevelDestination.cases)
                        menuViewBuilder.menuView
                            .navTabItem(destination: .menu)
                            .tag(TopLevelDestination.menu)
                    }
                }
            } else {
                authenticateViewBuilder.authenticateView
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            }
        }
    }
}
