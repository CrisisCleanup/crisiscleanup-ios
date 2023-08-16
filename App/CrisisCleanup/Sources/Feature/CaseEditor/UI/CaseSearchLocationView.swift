import SwiftUI

struct CaseSearchLocationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseSearchLocationViewModel

    @State var search = ""

    var body: some View {
        VStack {
            TextField("enter address", text: $search)
                .onChange(of: search) { newValue in
                    viewModel.searchQuery = search
                }
                .textFieldBorder()
                .padding(.bottom)

            ScrollView {
                LazyVStack {
                    let results = viewModel.searchResults
                    ForEach(results, id: \.key) { result in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(result.address.address)
                                HStack{
                                    Text(result.address.city + ",")
                                    Text(result.address.state + ",")
                                    Text(result.address.country)
                                }

                            }
                            Spacer()
                        }
                        .onTapGesture {
                            // TODO: save address for CreateEditCaseViewModel usage
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
        }
        .padding()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
