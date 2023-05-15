import SwiftUI

struct MenuView: View {
    @StateObject private var viewModel = MenuViewModel()

    var body: some View {
        Text("Menu \(viewModel.versionText)")
    }
}
