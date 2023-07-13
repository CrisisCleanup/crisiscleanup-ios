import SwiftUI

struct CaseFlagsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text("Case flags under construction")
    }
}
