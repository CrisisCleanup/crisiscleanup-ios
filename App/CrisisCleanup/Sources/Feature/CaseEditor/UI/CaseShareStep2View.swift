import SwiftUI

struct CaseShareStep2View: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Part 2")
        }
        .padding(.horizontal)
    }
}
