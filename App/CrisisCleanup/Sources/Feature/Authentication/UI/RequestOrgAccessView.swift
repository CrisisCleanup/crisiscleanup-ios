import SwiftUI

struct RequestOrgAccessView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: RequestOrgAccessViewModel

    @State var userInfo = UserInfoInputData()

    @FocusState private var focusState: TextInputFocused?

    private let focusableViewState = TextInputFocusableView()
    // TODO: Why is this necessary where other usages did not require additional state?
    @State private var isInputFocused = false

    var body: some View {
        let disabled = viewModel.editableViewState.disabled
        let isRequestingAccess = viewModel.isRequestingAccess

        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Group {
                        let requestInstructions = t.t("~~Request access by entering the email address of someone in your organization who already has an account.")
                        Text(requestInstructions)

                        TextField(t.t("invitationsVue.email"), text: $viewModel.emailAddress)
                            .textFieldBorder()
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.top, appTheme.listItemVerticalPadding)
                            .disableAutocorrection(true)
                            .focused($focusState, equals: TextInputFocused.authEmailAddress)
                            .disabled(disabled)
                            .onSubmit { focusState = .userFirstName }
                            .onAppear {
                                if viewModel.emailAddress.isBlank {
                                    focusState = TextInputFocused.authEmailAddress
                                }
                            }
                    }
                    .padding(.horizontal)

                    Text(t.t("~~Fill out your information"))
                        .fontHeader3()
                        .padding([.horizontal, .top])

                    UserInfoInputView(
                        languageOptions: $viewModel.languageOptions,
                        info: $userInfo,
                        focusState: $focusState
                    )
                    .padding(.horizontal)
                    .disabled(disabled)

                    Group {
                        Text(t.t("requestAccess.request_will_be_sent"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            viewModel.onVolunteerWithOrg()
                        } label: {
                            BusyButtonContent(
                                isBusy: isRequestingAccess,
                                text: t.t("actions.request_access")
                            )
                        }
                        .stylePrimary()
                        .padding(.bottom)
                        .disabled(disabled)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }

            if isInputFocused {
                OpenKeyboardActionsView()
            }
        }
        .navigationTitle(t.t("~~Signup"))
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: focusState) {
            focusableViewState.focusState = $0

            withAnimation {
                isInputFocused = focusState != nil
            }
        }
    }
}
