import SwiftUI

struct CaseAddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseAddNoteViewModel
    @State var note: String = ""

    var body: some View {
        VStack {
            HStack {
                Text(t.t("caseView.add_note"))
                    .font(.title)
            }

            TextEditor(text: $note)
                .frame(height: appTheme.rowItemHeight*5)
                .textFieldBorder()
                .padding()
                .tint(.black)

            HStack {
                Spacer()
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text(t.t("actions.cancel"))
                }
                .tint(.black)
                .padding(.trailing)

                Button {
                    // TODO: handle note addition
                } label: {
                    Text(t.t("actions.add"))
                }
                .tint(.black)
                .padding(.horizontal)

            }
            .padding()
            Spacer()
        }
    }
}
