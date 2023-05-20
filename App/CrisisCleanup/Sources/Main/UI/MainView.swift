import SwiftUI

struct MainView<ViewModel>: View where ViewModel: MainViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let menuBuilder: MenuBuilder

    var body: some View {
        TabView {
            CasesView()
                .navTabItem(destination: .cases)
            menuBuilder.menuView
                .navTabItem(destination: .menu)
        }
    }
}
