import SwiftUI

struct ViewListView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ViewListViewModel

    var body: some View {
        Text("View list \(viewModel.listId)")
    }
}
