import SwiftUI
import SVGView

struct CasesSearchView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesSearchViewModel

    var body: some View{
        let disabled = viewModel.isLoading

        VStack {
            Spacer()
            TextField("search hint", text: $viewModel.searchQuery)
                .autocapitalization(.none)
                .padding([.vertical])
                .disableAutocorrection(true)
                .disabled(disabled)
            Text("cases search")
            Spacer()
        }
        .padding()
    }
}
