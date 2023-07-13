import SwiftUI

struct CaseAddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseAddNoteViewModel

    var body: some View {
        Text("Add note under construction")
    }
}
