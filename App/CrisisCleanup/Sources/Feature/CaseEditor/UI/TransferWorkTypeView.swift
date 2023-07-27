import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    @State var isKeyboardOpen = false

    var body: some View {
        if viewModel.isTransferable {
            let isSaving = viewModel.isTransferring
            let disabled = isSaving

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {

                        if viewModel.transferType == .request {
                            RequestView()
                                .environmentObject(viewModel)
                        } else {
                            ReleaseView()
                                .environmentObject(viewModel)
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

    @State var tempString = ""
    @State var tempWorkTypeState: [WorkType: Bool] = [:]

    @State var reqtDescAS: AttributedString = AttributedString()
    @State var respNoteAS: AttributedString = AttributedString()

    var fakeContacts: [PersonContact] = [
        PersonContact(id: 1, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789"),
        PersonContact(id: 2, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789"),
        PersonContact(id: 3, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "123456789")
    ]

    private func binding(key: WorkType) -> Binding<Bool> {
        return .init(
            get: { self.tempWorkTypeState[key, default: false] },
            set: { self.tempWorkTypeState[key] = $0 })
    }

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

        Text(t.t("workTypeRequestModal.contacts"))
            .bold()
            .padding(.bottom, 4)
            .onAppear {
                // placeholder
                tempWorkTypeState = viewModel.transferWorkTypesState
            }

        ForEach(fakeContacts, id: \.id) { contact in
            VStack(alignment: .leading) {
                Text(contact.fullName)
                HStack {
                    Link(contact.email, destination: URL(string: "mailto:\(contact.email)")!)
                    Link(contact.mobile, destination: URL(string: "tel:\(contact.mobile)")!)
                }
            }.padding(.bottom)
        }

        ForEach(viewModel.contactList, id: \.self) { contact in
            VStack(alignment: .leading) {
                Text(contact)
                //                                    HStack {
                //                                        Link(contact.email, destination: URL(string: "mailto:\(contact.email)")!)
                //                                        Link(contact.mobile, destination: URL(string: "tel:\(contact.mobile)")!)
                //                                    }
            }.padding(.bottom)
        }

        if(viewModel.errorMessageWorkType.value.isNotBlank && !tempWorkTypeState.values.contains(true)) {
            Text(t.t(viewModel.errorMessageWorkType.value))
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        let workTypeSelections = Array(viewModel.transferWorkTypesState.enumerated())
        ForEach(workTypeSelections, id: \.self.1.key.id) { (index, entry) in
            let (workType, isSelected) = entry
            HStack {
                CheckboxView(checked: binding(key: workType), text: t.t(workType.workTypeLiteral))
                    .disabled(workTypeSelections.count == 1)
                Spacer()
            }

        }

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

            if(viewModel.errorMessageReason.value.isNotBlank && tempString.isBlank) {
                Text(t.t(viewModel.errorMessageReason.value))
                    .foregroundColor(appTheme.colors.primaryRedColor)
            }

            LargeTextEditor(text: $tempString)
                .padding(.vertical)
        }

    }
}

struct ReleaseView: View {
    @EnvironmentObject var viewModel: TransferWorkTypeViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    @State var tempWorkTypeState: [WorkType: Bool] = [:]
    @State var tempString = ""

    private func binding(key: WorkType) -> Binding<Bool> {
            return .init(
                get: { self.tempWorkTypeState[key, default: false] },
                set: { self.tempWorkTypeState[key] = $0 })
        }

    var body: some View {
        Text(t.t("caseView.please_justify_release"))
            .onAppear {
                tempWorkTypeState = viewModel.transferWorkTypesState
            }
            .padding(.bottom)

        if(viewModel.errorMessageWorkType.value.isNotBlank) {
            Text(t.t(viewModel.errorMessageWorkType.value))
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        TextEditor(text: $tempString)
            .frame(height: appTheme.rowItemHeight*5)
            .textFieldBorder()
            .padding(.vertical)
            .tint(.black)

        if(viewModel.errorMessageReason.value.isNotBlank) {
            Text(t.t(viewModel.errorMessageReason.value))
                .foregroundColor(appTheme.colors.primaryRedColor)
        }

        let workTypeSelections = Array(viewModel.transferWorkTypesState.enumerated())
        ForEach(workTypeSelections, id: \.self.1.key.id) { (index, entry) in
            let (workType, isSelected) = entry
            HStack {
                CheckboxView(checked: binding(key: workType), text: t.t(workType.workTypeLiteral))
                    .disabled(workTypeSelections.count == 1)
                Spacer()
            }

        }
    }
}

struct TransferWorkTypeActions: View {
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
                viewModel.commitTransfer()
            } label: {
                Text(t.t("actions.ok"))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal)
    }
}
