import SwiftUI

struct MenuView<ViewModel>: View where ViewModel: MenuViewModelProtocol {
    @ObservedObject var viewModel: ViewModel

    var body: some View{
        List {
            Text("Menu \(viewModel.versionText)")
        }
    }
}
