import SwiftUI
import FlowStackLayout

struct CaseShareStep2View: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    @State var shareMessage = ""

    @State var origin  = CGPointZero
    @State var boxY: CGFloat = 0
    @State var suggBoxSize = CGSize()
    @State var suggBoxOrigin = CGPointZero
    @State var yDiff:CGFloat = 0
    @State var offset: CGFloat = 0

    var body: some View {
        let shareByEmail = viewModel.isEmailContactMethod
        let shareByEmailOption = t.t("shareWorksite.email")
        GeometryReader { vstackReader in
            ScrollView {
                ZStack {

                    VStack(alignment: .leading) {

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

                        // Text(offset.description)

                        ShareReceiverContactList()

                        // TODO: Show error message if not empty
                        // TODO: Add checkbox at tend to submit as well
                        let manualKey = viewModel.isEmailContactMethod ? "shareWorksite.manually_enter_emails" : "shareWorksite.manually_enter_phones"
                        TextField(t.t(manualKey), text: $viewModel.receiverContactManual)
                        .textFieldBorder()
                        .onSubmit {
                            viewModel.onAddContact(viewModel.receiverContactManual)
                        }

                        let searchTitleKey = viewModel.isEmailContactMethod ? "shareWorksite.search_emails" : "shareWorksite.search_phones"
                        TextField(t.t(searchTitleKey), text: $viewModel.receiverContactSuggestion)
                        .textFieldBorder()
                        .background(
                            GeometryReader { reader in
                                Color.clear
                                    .onAppear {
                                        origin = reader.frame(in: .named("VSTACK")).origin
                                        boxY = reader.size.height
                                    }
                                    .onChange(of: viewModel.receiverContacts.count) { _ in
                                        origin = reader.frame(in: .named("VSTACK")).origin
                                        suggBoxOrigin = CGPointZero
                                        yDiff = 0
                                    }
                            }

                        )

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
                    .padding(.horizontal)

                    if(viewModel.contactOptions.isNotEmpty) {

                        VStack {
                            HStack {
                                Spacer()
                                SuggestionsBox(search: $viewModel.receiverContactSuggestion)
                                    .background(
                                        GeometryReader { reader in
                                            Color.clear
                                                .onAppear {
//                                                    suggBoxOrigin = reader.frame(in: .named("VSTACK")).origin
//                                                    print(reader.frame(in: .named("VSTACK")).size)
//                                                    print(origin.debugDescription + suggBoxOrigin.debugDescription)
//                                                    print(suggBoxOrigin.y - origin.y)
//                                                    yDiff = suggBoxOrigin.y - origin.y
//                                                    suggBoxSize = reader.frame(in: .named("VSTACK")).size
//                                                    offset = yDiff
//                                                    print(offset)

                                                }
                                                .onDisappear() {
                                                    offset = 0
                                                    yDiff = 0
                                                    suggBoxSize = CGSize()
                                                }
                                                .onChange(of: reader.frame(in: .named("VSTACK")).size) { size in
                                                    let diff = origin.y - suggBoxOrigin.y
                                                    if(suggBoxSize == CGSize()) {
                                                        suggBoxSize = size
                                                        suggBoxOrigin = reader.frame(in: .named("VSTACK")).origin
                                                        print("origin: \(origin)")
                                                        print("suggBoxorigin: \(suggBoxOrigin)")
                                                        print("suggSize: \(suggBoxSize)")
                                                        offset = origin.y - suggBoxOrigin.y
                                                        print("offset :\(offset)")
                                                        print("newOrigin: \(suggBoxOrigin.y + offset)")
                                                    }
//                                                    if(suggBoxOrigin == CGPointZero) {
//                                                        suggBoxOrigin = reader.frame(in: .named("VSTACK")).origin
//
//                                                        print(reader.frame(in: .named("VSTACK")).size)
//                                                        print(origin.debugDescription + suggBoxOrigin.debugDescription)
//                                                        print(suggBoxOrigin.y - origin.y)
//                                                        yDiff = suggBoxOrigin.y - origin.y
//                                                    }
//                                                    yDiff = suggBoxOrigin.y - origin.y
//                                                    offset = -yDiff - suggBoxSize.height/2 - boxY/2 - 10
//                                                    print(offset)
                                                }
                                                .onChange(of: viewModel.contactOptions) { change in
//                                                    print("after ydiff " + reader.frame(in: .named("VSTACK")).origin.debugDescription)
//                                                    print(origin.debugDescription + suggBoxOrigin.debugDescription)
                                                    print("here")
                                                    if(suggBoxSize != CGSize()) {
                                                        suggBoxSize = reader.frame(in: .named("VSTACK")).size
                                                        suggBoxOrigin = reader.frame(in: .named("VSTACK")).origin
                                                        print("origin: \(origin)")
                                                        print("suggBoxorigin: \(suggBoxOrigin)")
                                                        print("suggSize: \(suggBoxSize)")
//                                                        offset = origin.y - suggBoxOrigin.y
                                                        print("offset :\(offset)")
                                                        print("newOrigin: \(suggBoxOrigin.y + offset)")
                                                    }
                                                }
                                        }
                                    )
                                Spacer()
                            }
                            .offset(y: offset)// TODO: account for keyboard appearing. Adjust orgin when contacts are added

                        }


                    }

                }
                .environmentObject(viewModel)

            }

        }.coordinateSpace(name: "VSTACK")
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


struct SuggestionsBox: View {

    @EnvironmentObject var viewModel: CaseShareViewModel

    @State var scrollSize = CGSize()
    @Binding var search: String

    var body: some View {
        HStack {
            ScrollView {
                VStack {
                    ForEach(viewModel.contactOptions, id:\.self) { contact in
                        VStack(alignment: .leading) {
                            if(contact == viewModel.contactOptions.first) {
                                Divider()
                                    .frame(height: 2)
                                    .hidden()
                            }
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                    Text(contact.contactValue)

                                }
                                Spacer()
                            }
                            .padding([.horizontal])


                            if(contact != viewModel.contactOptions.last) {
                                Divider()
                                    .frame(height: 2)
                                    .overlay(Color(UIColor.systemGray5))
                            } else {
                                Divider()
                                    .frame(height: 2)
                                    .hidden()
                            }
                        }
                        .onTapGesture {
                            viewModel.onAddContact(contact)
                            search = ""
                        }
                    }
                    .overlay {
                        GeometryReader { reader in
                            Color.clear
                                .onAppear {
                                    scrollSize = reader.size
                                }
                        }
                    }

                }

            }.frame(height: viewModel.contactOptions.count <= 3 ? scrollSize.height * CGFloat(viewModel.contactOptions.count) : scrollSize.height * 3)
        }
        .background(Color(red: 245, green: 245, blue: 245))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.5), radius: 10)
    }
}
