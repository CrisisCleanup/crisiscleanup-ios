import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        Text("Transfer work type under construction")
    }
}
