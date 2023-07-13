import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        Text("Transfer work type under construction")
    }
}
