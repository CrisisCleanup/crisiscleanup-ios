import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    @ObservedObject private var focusableViewState = TextInputFocusableView()

    var body: some View {
        if viewModel.isTransferable {
            let isSaving = viewModel.isTransferring
            let disabled = isSaving

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        if viewModel.transferType == .request {
                            RequestView()
                        } else {
                            ReleaseView()
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)

                if focusableViewState.isFocused {
                    OpenKeyboardActionsView()
                } else {
                    TransferWorkTypeActions()
                        .disabled(disabled)
                        .listItemPadding()
   }
            }
            .frame(maxWidth: UIScreen.main.bounds.size.width)
            .onChange(of: viewModel.isTransferred) { b in
                if (b) {
                    dismiss()
                }
            }
            .screenTitle(viewModel.screenTitle)
            .hideNavBarUnderSpace()
            .onAppear { viewModel.onViewAppear() }
            .onDisappear { viewModel.onViewDisappear() }
            .environment(\.translator, viewModel)
            .environmentObject(viewModel)
            .environmentObject(focusableViewState)
        } else {
            Text("Invalid state. Go back")
        }
    }
}

struct RequestView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    @State var reqtDescAS: AttributedString = AttributedString()
    @State var respNoteAS: AttributedString = AttributedString()

    var body: some View {
        Text(reqtDescAS)
            .onChange(of: viewModel.requestDescription) { desc in
                DispatchQueue.main.async {
                    let data = Data(desc.utf8)
                    if let attributedString = try? NSMutableAttributedString(
                        data: data,
                        options: [
                            .documentType: NSMutableAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        // TODO: Keep consistent with font styles
                        attributedString.replaceFont(font: .systemFont(ofSize: 16), size: 16)
                        reqtDescAS = AttributedString(attributedString)
                    }
                }
            }

        if viewModel.contactList.isNotEmpty {
            Text(t.t("workTypeRequestModal.contacts"))
                .fontHeader4()
                .padding(.bottom, appTheme.listItemVerticalPadding)

            ForEach(viewModel.contactList, id: \.self) { contact in
                VStack(alignment: .leading) {
                    Text("\(contact.contactName) (\(contact.orgName))")

                    if contact.hasContactInfo {
                        HStack(spacing: appTheme.gridItemSpacing) {
                            if contact.email.isNotBlank {
                                Text(contact.email)
                                    .if (contact.isValidEmail) {
                                        $0.customLink(urlString: "mailto:\(contact.email)")
                                    }
                            }
                            if contact.mobile.isNotBlank {
                                Text(contact.mobile)
                                    .if (contact.isValidMobile) {
                                        $0.customLink(urlString: "tel:\(contact.mobile)")
                                    }
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
        }

        TransferWorkTypeSection()

        Group {
            Text(respNoteAS)
                .onAppear {
                    DispatchQueue.main.async {
                        let desc = t.t("workTypeRequestModal.please_add_respectful_note")
                        let data = Data(desc.utf8)
                        if let attributedString = try? NSMutableAttributedString(
                            data: data,
                            options: [
                                .documentType: NSMutableAttributedString.DocumentType.html
                            ],
                            documentAttributes: nil
                        ) {

                            attributedString.replaceFont(font: .systemFont(ofSize: 16), size: 16)
                            respNoteAS = AttributedString(attributedString)
                        }
                    }
                }

            VStack(alignment: .leading) {
                Text("\u{2022} " + t.t("workTypeRequestModal.reason_member_of_faith_community"))
                Text("\u{2022} " + t.t("workTypeRequestModal.reason_working_next_door"))
                Text("\u{2022} " + t.t("workTypeRequestModal.reason_we_did_the_work"))
            }
            .padding([.bottom, .leading])

            TransferWorkTypeReasonSection()
        }
    }
}

struct ReleaseView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        Text(t.t("caseView.please_justify_release"))
            .padding(.bottom)

        TransferWorkTypeReasonSection()

        TransferWorkTypeSection()
    }
}

private struct TransferWorkTypeReasonSection: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        if viewModel.errorMessageReason.isNotBlank {
            Text(viewModel.errorMessageReason)
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        LargeTextEditor(
            text: $viewModel.transferReason,
            placeholder: viewModel.reasonHint
        )
            .padding(.vertical)
    }
}

private struct TransferWorkTypeSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        if viewModel.errorMessageWorkType.isNotBlank {
            Text(viewModel.errorMessageWorkType)
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        ForEach(viewModel.workTypeList, id: \.self.id) { workType in
            let id = workType.id
            let isChecked = viewModel.workTypesState[id] ?? false
            HStack {
                StatelessCheckboxView(
                    checked: isChecked,
                    text: t.t("workType.\(workType.workTypeLiteral)")
                ) {
                    viewModel.workTypesState[id] = !isChecked
                }
                Spacer()
            }
        }
    }
}

private struct TransferWorkTypeActions: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text(t.t("actions.cancel"))
            }
            .styleCancel()

            Button {
                _ = viewModel.commitTransfer()
            } label: {
                Text(t.t("actions.ok"))
            }
            .stylePrimary()
        }
    }
}
