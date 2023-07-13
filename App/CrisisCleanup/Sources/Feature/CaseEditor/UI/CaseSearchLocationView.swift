import SwiftUI

struct CaseSearchLocationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseSearchLocationViewModel

    var body: some View {
        Text("Case search location under construction")
    }
}
