import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    @State var reason = ""

    @State var isKeyboardOpen = false

    var body: some View {
        if viewModel.isTransferable {
            let isSaving = viewModel.isTransferring
            let disabled = isSaving

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {

                        if viewModel.transferType == .request {
                            RequestView(reason: $reason)
                        } else {
                            ReleaseView(reason: $reason)
                        }

                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)

                if isKeyboardOpen {
                    OpenKeyboardActionsView()
                } else {
                    TransferWorkTypeActions()
                        .disabled(disabled)
                        .environmentObject(viewModel)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.size.width)
            .onReceive(keyboardPublisher) { isVisible in
                isKeyboardOpen = isVisible
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.screenTitle)
                }
            }
            .hideNavBarUnderSpace()
            .onAppear { viewModel.onViewAppear() }
            .onDisappear { viewModel.onViewDisappear() }
            .environmentObject(viewModel)
        } else {
            Text("Invalid state. Go back")
        }
    }
}

struct RequestView: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var reason: String

    @State var reqtDescAS: AttributedString = AttributedString()
    @State var respNoteAS: AttributedString = AttributedString()

    var fakeContacts: [PersonContact] = [
//        PersonContact(id: 1, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789"),
//        PersonContact(id: 2, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789"),
//        PersonContact(id: 3, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789")
    ]

    var body: some View {
//        HtmlAS(htmlContent: viewModel.requestDescription) // for some reason this doesn't work

        Text(reqtDescAS)
            .onReceive(viewModel.$requestDescription) { desc in
                DispatchQueue.main.async {
                    let data = Data(desc.utf8)
                    if let attributedString = try? NSMutableAttributedString(
                        data: data,
                        options: [
                            .documentType: NSMutableAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        attributedString.replaceFont(font: .systemFont(ofSize: 16), size: 16)
                        reqtDescAS = AttributedString(attributedString)
                    }
                }
            }

        if viewModel.contactList.isNotEmpty {
            Text(t.t("workTypeRequestModal.contacts"))
                .fontHeader4()
                .padding(.bottom, 4)

            //        ForEach(fakeContacts, id: \.id) { contact in
            //            VStack(alignment: .leading) {
            //                Text(contact.fullName)
            //                HStack {
            //                    Link(contact.email, destination: URL(string: "mailto:\(contact.email)")!)
            //                    Link(contact.mobile, destination: URL(string: "tel:\(contact.mobile)")!)
            //                }
            //            }.padding(.bottom)
            //        }

            ForEach(viewModel.contactList, id: \.self) { contact in
                VStack(alignment: .leading) {
                    Text(contact)
                    //                                    HStack {
                    //                                        Link(contact.email, destination: URL(string: "mailto:\(contact.email)")!)
                    //                                        Link(contact.mobile, destination: URL(string: "tel:\(contact.mobile)")!)
                    //                                    }
                }.padding(.bottom)
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

            TransferWorkTypeReasonSection(reason: $reason)
        }
    }
}

struct ReleaseView: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var reason: String

    var body: some View {
        Text(t.t("caseView.please_justify_release"))
            .padding(.bottom)

        TransferWorkTypeReasonSection(reason: $reason)

        TransferWorkTypeSection()
    }
}

private struct TransferWorkTypeReasonSection: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    @Binding var reason: String

    var body: some View {
        if viewModel.errorMessageReason.value.isNotBlank {
            Text(viewModel.errorMessageReason.value)
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        LargeTextEditor(text: $reason)
            .padding(.vertical)
    }
}

private struct TransferWorkTypeSection: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel

    var body: some View {
        if viewModel.errorMessageWorkType.value.isNotBlank {
            Text(viewModel.t(viewModel.errorMessageWorkType.value))
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        let workTypeSelections = Array(viewModel.transferWorkTypesState.enumerated())
        ForEach(workTypeSelections, id: \.self.1.key.id) { (index, entry) in
            let (workType, _) = entry
            let id = workType.id
            let isChecked = viewModel.workTypesState[id] ?? false
            HStack {
                CheckboxChangeView(
                    checked: isChecked,
                    text: viewModel.t(workType.workTypeLiteral)
                ) { checked in
                    viewModel.workTypesState[id] = checked
                }
                Spacer()
            }
        }
    }
}

private struct TransferWorkTypeActions: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text(t.t("actions.cancel"))
            }
            .buttonStyle(CancelButtonStyle())

            Button {
                _ = viewModel.commitTransfer()
            } label: {
                Text(t.t("actions.ok"))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal)
    }
}
