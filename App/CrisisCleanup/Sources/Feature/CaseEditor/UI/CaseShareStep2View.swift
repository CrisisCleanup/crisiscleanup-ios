import SwiftUI
import FlowStackLayout

struct CaseShareStep2View: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    @State var shareMessage = ""

    @FocusState private var isQueryFocused: Bool
    @State private var animateTopSearchBar = false

    var body: some View {
        let shareByEmail = viewModel.isEmailContactMethod
        let shareByEmailOption = t.t("shareWorksite.email")

        ScrollView {
            VStack(alignment: .leading) {
                Spacer(minLength: 8)

                if !animateTopSearchBar {
                    Text(t.t("shareWorksite.share_via_email_phone_intro"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom)

                    HStack {
                        Text(t.t("shareWorksite.share_case_method"))
                            .bold()
                        Spacer()
                    }

                    Group {
                        RadioButton(text: shareByEmailOption, isSelected: shareByEmail) {
                            viewModel.isEmailContactMethod = true
                        }
                        RadioButton(text: t.t("shareWorksite.sms_text_message"), isSelected: !shareByEmail) {
                            viewModel.isEmailContactMethod = false
                        }
                    }
                    .padding()
                }

                ShareReceiverContactList()

                if !animateTopSearchBar {
                    let manualErrorMessage = viewModel.contactErrorMessage
                    if manualErrorMessage.isNotBlank {
                        // TODO: Style
                        Text(manualErrorMessage)
                            .padding(.vertical)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                    }

                    let manualKey = viewModel.isEmailContactMethod ? "shareWorksite.manually_enter_emails" : "shareWorksite.manually_enter_phones"
                    HStack {
                        TextField(
                            t.t(manualKey),
                            text: $viewModel.receiverContactManual
                        )
                        .textFieldBorder()
                        .onSubmit {
                            viewModel.onAddContact(viewModel.receiverContactManual)
                        }

                        Button {
                            viewModel.onAddContact(viewModel.receiverContactManual)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .padding()
                        .disabled(viewModel.receiverContactManual.isBlank)
                    }
                    .padding(.bottom)
                }

                HStack {
                    let searchTitleKey = viewModel.isEmailContactMethod ? "shareWorksite.search_emails" : "shareWorksite.search_phones"
                    // TODO: Keep this view at the top when focused and not scrollable
                    TextField(
                        t.t(searchTitleKey),
                        text: $viewModel.receiverContactSuggestion
                    )
                    .focused($isQueryFocused)
                    .onChange(of: isQueryFocused) { isFocused in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animateTopSearchBar = isFocused
                        }
                    }
                    .textFieldBorder()

                    if animateTopSearchBar {
                        Button {
                            viewModel.receiverContactSuggestion = ""
                            isQueryFocused = false
                        } label: {
                            Text(t.t("actions.close"))
                        }
                        // TODO: Common dimensions
                        .padding(.leading, 8)
                    }
                }

                if animateTopSearchBar {
                    ForEach(viewModel.contactOptions, id:\.name) { contact in
                        VStack(alignment: .leading) {
                            Text(contact.name)
                            Text(contact.contactValue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .onTapGesture {
                            viewModel.onAddContact(contact)
                        }
                    }
                } else {
                    Group {
                        Text(t.t("shareWorksite.add_message"))
                            .padding(.top)
                            .fixedSize(horizontal: false, vertical: true)

                        LargeTextEditor(text: $shareMessage)
                    }
                    .padding(.bottom)

                    Spacer()

                    CaseShareBottomActions(message: $shareMessage)
                }
            }
            .padding(.horizontal)
        }
        .environmentObject(viewModel)
        .scrollDismissesKeyboard(.immediately)
    }
}

struct CaseShareBottomActions: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: CaseShareViewModel

    @Binding var message: String

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text(t.t("actions.cancel"))
                    .padding()
            }
            .styleCancel()

            Button {
                viewModel.onShare(message)
            } label: {
                Text(t.t("actions.share"))
                    .padding()
            }
            .stylePrimary()
            .disabled(!viewModel.isShareEnabled)
        }
    }
}

private struct ShareReceiverContactList: View {
    @EnvironmentObject var viewModel: CaseShareViewModel

    var body: some View {
        FlowStack(
            alignment: .leading,
            // TODO: Common dimensions
            horizontalSpacing: 8,
            verticalSpacing: 8
        ) {
            let contacts = viewModel.receiverContacts
            ForEach(Array(contacts.enumerated()), id: \.offset) { (index, contact) in
                ShareReceiverContactChip(contact: contact.contactValue) {
                    viewModel.deleteContact(index)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private struct ShareReceiverContactChip: View {
    let contact: String
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
            }
            Text(contact)
        }
        .padding()
        .background(appTheme.colors.attentionBackgroundColor)
        .cornerRadius(40)
        .tint(.black)
    }
}
