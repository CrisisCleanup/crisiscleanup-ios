import SwiftUI

struct CaseHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseHistoryViewModel

    var body: some View {
        Text("Case history under construction")
    }
}
