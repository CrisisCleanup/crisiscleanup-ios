import SwiftUI

struct MainView<ViewModel>: View where ViewModel: MainViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let menuViewBuilder: MenuViewBuilder

    @State private var selectedTab = TopLevelDestination.menu
    var body: some View {
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
    }
}
