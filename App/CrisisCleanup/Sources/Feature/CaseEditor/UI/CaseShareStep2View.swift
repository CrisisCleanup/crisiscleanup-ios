import SwiftUI
import FlowStackLayout

struct CaseShareStep2View: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    @State var shareMessage = ""

    @ObservedObject private var focusableViewState = TextInputFocusableView()
    @FocusState private var focusState: TextInputFocused?
    @State private var animateTopSearchBar = false

    var body: some View {
        let shareByEmail = viewModel.isEmailContactMethod
        let shareByEmailOption = t.t("shareWorksite.email")

        CaseShareNotSharableMessage(message: viewModel.notSharableMessage)
            .padding([.top, .horizontal])

        WrappingHeightScrollView {
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
                        // TODO: Common styles
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
                        .focused($focusState, equals: .anyTextInput)
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
                    TextField(
                        t.t(searchTitleKey),
                        text: $viewModel.receiverContactSuggestion
                    )
                    .focused($focusState, equals: .querySuggestionsInput)
                    .onReceive(focusableViewState.$isQueryInputFocused) { b in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animateTopSearchBar = b
                        }
                    }
                    .textFieldBorder()

                    if animateTopSearchBar {
                        Button {
                            viewModel.receiverContactSuggestion = ""
                            focusableViewState.clear()
                            hideKeyboard()
                        } label: {
                            Text(t.t("actions.close"))
                        }
                        .padding(.leading, appTheme.gridItemSpacing)
                    }
                }

                if !animateTopSearchBar {
                    Group {
                        Text(t.t("shareWorksite.add_message"))
                            .padding(.top)
                            .fixedSize(horizontal: false, vertical: true)

                        LargeTextEditor(text: $shareMessage)
                    }
                    .padding(.bottom)
                }
            }
            .padding(.horizontal)
        }
        .environmentObject(viewModel)
        .environmentObject(focusableViewState)
        .onChange(of: focusState) { focusableViewState.focusState = $0 }

        if animateTopSearchBar {
            ScrollLazyVGrid {
                ForEach(viewModel.contactOptions, id:\.contactValue) { contact in
                    VStack(alignment: .leading) {
                        Text(contact.name)
                        Text(contact.contactValue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, appTheme.listItemVerticalPadding)
                    .frame(minHeight: appTheme.rowItemHeight)
                    .onTapGesture {
                        viewModel.onAddContact(contact)
                    }
                }
            }
        } else if !focusableViewState.isQueryInputFocused {
            Spacer()

            if focusableViewState.isFocused {
                OpenKeyboardActionsView()
            } else {
                CaseShareBottomActions(message: $shareMessage)
                    .environmentObject(viewModel)
                    .padding(.horizontal)
                    .padding(.vertical, appTheme.listItemVerticalPadding)
            }
        }
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
            horizontalSpacing: appTheme.gridItemSpacing,
            verticalSpacing: appTheme.gridItemSpacing
        ) {
            let contacts = viewModel.receiverContacts
            ForEach(Array(contacts.enumerated()), id: \.offset) { (index, contact) in
                ShareReceiverContactChip(contact: contact.contactValue) {
                    viewModel.deleteContact(index)
                }
            }
        }
        .padding(.bottom)
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
        // TODO: Is there a setting for fully rounded? If not common dimensions.
        .cornerRadius(40)
        .tint(.black)
    }
}
