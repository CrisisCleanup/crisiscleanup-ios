import SwiftUI
import FlowStackLayout

struct CaseShareStep2View: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    @State var selected = ""
    @State var manual = ""
    @State var search = ""
    @State var field = ""
    @State var selectedContact = ShareContactInfo(name: "", contactValue: "", isEmail: false)
    @State var origin  = CGPointZero
    @State var boxY: CGFloat = 0
    @State var suggBoxSize = CGSize()
    @State var suggBoxOrigin = CGPointZero
    @State var yDiff:CGFloat = 0
    @State var offset: CGFloat = 0

    var body: some View {
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

                        RadioButtons(
                            selected: $selected,
                            options: [t.t("shareWorksite.email"), t.t("shareWorksite.sms_text_message")]
                        )
                        .onAppear() {
                            selected = t.t("shareWorksite.email")
                        }
                        .onChange(of: selected) { _ in
                            viewModel.isEmailContactMethod = selected == t.t("shareWorksite.email")
                        }
                        .padding()

                        Text(offset.description)

                        FlowStack(
                            alignment: .leading,
                            horizontalSpacing: 8,
                            verticalSpacing: 8
                        ) {
                            let contacts = viewModel.receiverContacts
                            ForEach(contacts, id: \.self) { contact in
                                let index = Int(contacts.firstIndex(of: contact)!.magnitude)
                                ContactChip(contact: contact.contactValue, index: index)
                                    .environmentObject(viewModel)
                            }
                        }
                        .padding(.bottom, 4)

                        let manualTitle = viewModel.isEmailContactMethod ? t.t("shareWorksite.manually_enter_emails") : t.t("shareWorksite.manually_enter_phones")
                        TextField(manualTitle, text: $manual)
                        .textFieldBorder()
                        .onSubmit {
                            viewModel.onAddContact(manual)
                        }

                        let searchTitle = viewModel.isEmailContactMethod ? t.t("shareWorksite.search_emails") : t.t("shareWorksite.search_phones")
                        TextField(searchTitle, text: $search)
                        .onChange(of: search) { _ in
                            viewModel.receiverContactSuggestion = search
                        }
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
                                .fixedSize(horizontal: false, vertical: true)

                            LargeTextEditor(text: $field)
                        }

                        Spacer()

                        ShareNav(message: field)
                            .environmentObject(viewModel)

                    }
                    .padding(.horizontal)


                    if(viewModel.contactOptions.isNotEmpty) {

                        VStack {
                            HStack {
                                Spacer()
                                SuggestionsBox(search: $search)
                                    .environmentObject(viewModel)
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


            }

        }.coordinateSpace(name: "VSTACK")
    }
}

struct ShareNav: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: CaseShareViewModel

    var message: String

    var body: some View {
        HStack {
            Button {
                dismiss.callAsFunction()
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
            .disabled(viewModel.isShareEnabled)
        }
    }
}

struct ContactChip: View {
    @EnvironmentObject var viewModel: CaseShareViewModel

    var contact: String
    var index: Int

    var body: some View {
        HStack {
            Button {
                viewModel.deleteContact(index)
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
                            viewModel.contactOptions = []
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
