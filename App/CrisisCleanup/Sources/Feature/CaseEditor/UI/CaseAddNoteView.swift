import SwiftUI

struct CaseAddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseAddNoteViewModel
    @State var note: String = ""

    var body: some View {
        VStack {
            TextEditor(text: $note)
                .frame(height: appTheme.rowItemHeight*5)
                .textFieldBorder()
                .padding()
                .tint(.black)

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text(t.t("actions.cancel"))
                }
                .tint(.black)

                Button {
                    viewModel.onAddNote(note)
                    dismiss()
                } label: {
                    Text(t.t("actions.add"))
                }
                .tint(.black)
                .padding(.horizontal)

            }
            .padding(.horizontal)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t.t("caseView.add_note"))
            }
        }
    }
}
