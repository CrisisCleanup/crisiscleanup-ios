import SwiftUI
import SVGView

struct CasesFilterView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesFilterViewModel

    var body: some View {
        ZStack {
            VStack {
                Text("Filter under construction")

                Spacer()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
