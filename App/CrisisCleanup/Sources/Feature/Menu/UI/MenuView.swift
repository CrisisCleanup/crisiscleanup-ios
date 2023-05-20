import SwiftUI

struct MenuView<ViewModel>: View where ViewModel: MenuViewModelProtocol {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        Text("Menu \(viewModel.versionText)")
    }
}
