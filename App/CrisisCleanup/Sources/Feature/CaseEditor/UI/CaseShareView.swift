import SwiftUI

struct CaseShareView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    var body: some View {
        Text("Case share under construction")
    }
}
