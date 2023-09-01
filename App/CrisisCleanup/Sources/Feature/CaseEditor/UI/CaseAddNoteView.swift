import SwiftUI

struct CaseAddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseAddNoteViewModel
    @State var note: String = ""

    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        VStack {
            TextEditor(text: $note)
                .focused($focusState, equals: .anyTextInput)
                .frame(height: appTheme.rowItemHeight*3)
                .textFieldBorder()
                .padding()
                .tint(.black)
                .onAppear {
                    focusState = .anyTextInput
                }

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
        .screenTitle(t.t("caseView.add_note"))
    }
}
