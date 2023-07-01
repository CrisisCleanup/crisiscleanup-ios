import SwiftUI
import SVGView

struct CasesSearchView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesSearchViewModel
    let casesFilterViewBuilder: CasesFilterViewBuilder

    @State var openFilters = false

    var body: some View{
        let isLoading = viewModel.isLoading
        let isSelectingResult = viewModel.isSelectingResult

        ZStack {
            VStack {
                // TODO: Style with border and padding
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }

                    TextField("search hint", text: $viewModel.searchQuery)
                        .autocapitalization(.none)
                        .padding([.vertical])
                        .disableAutocorrection(true)
                        .disabled(isSelectingResult)

                    Button {
                        openFilters = true
                    } label: {
                        // TODO: Use component
                        Image("ic_dials", bundle: .module)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)
                    }
                }
                Text("Instruction or text feedback")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("recents list")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("or search results scrollable list")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("depending on query length, and results")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding()

            VStack {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .navigationDestination(isPresented: $openFilters) {
            if openFilters {
                casesFilterViewBuilder.casesFilterView
                    .onDisappear {
                        openFilters = false
                    }
            }
        }
    }
}
