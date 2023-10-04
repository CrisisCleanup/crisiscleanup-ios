import SwiftUI

struct RequestOrgAccessView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: RequestOrgAccessViewModel

    @FocusState private var focusState: TextInputFocused?

    private let focusableViewState = TextInputFocusableView()
    // TODO: Why is this necessary where other usages did not require additional state?
    @State private var isInputFocused = false

    var body: some View {
        VStack {
            if viewModel.isInviteRequested {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(statusClosedColor)

                Text(viewModel.requestSentTitle)
                    .fontHeader1()
                    .padding()

                Text(viewModel.requestSentText)
                    .padding(.horizontal)

                Spacer()

                Image("worker_wheelbarrow_world_background", bundle: .module)
                    .padding(.leading, 180)

                Spacer()
            } else {
                RequestOrgUserInfoInputView(
                    showEmailInput: viewModel.showEmailInput,
                    focusState: $focusState
                )

                if isInputFocused {
                    OpenKeyboardActionsView()
                }
            }
        }
        .navigationTitle(viewModel.screenTitle)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
        .onChange(of: viewModel.errorFocus) { newValue in
            if let errorFocus = newValue {
                focusState = errorFocus
            }
        }
        .onChange(of: focusState) {
            focusableViewState.focusState = $0
            viewModel.errorFocus = nil

            withAnimation {
                isInputFocused = focusState != nil
            }
        }
    }
}

private struct RequestOrgUserInfoInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: RequestOrgAccessViewModel
    @EnvironmentObject var editableView: EditableView

    var showEmailInput = false

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        let disabled = editableView.disabled
        let isRequestingInvite = viewModel.isRequestingInvite

        let requestInstructions = t.t("~~Request access by entering the email address of someone in your organization who already has an account.")

        ScrollView {
            VStack(alignment: .leading) {
                if showEmailInput {
                    Group {
                        Text(requestInstructions)
                            .padding(.bottom, appTheme.listItemVerticalPadding)

                        if viewModel.emailAddressError.isNotBlank {
                            Text(viewModel.emailAddressError)
                                .foregroundColor(appTheme.colors.primaryRedColor)
                        }
                        TextField(t.t("requestAccess.existing_member_email"), text: $viewModel.emailAddress)
                            .textFieldBorder()
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused(focusState, equals: TextInputFocused.authEmailAddress)
                            .disabled(disabled)
                            .onSubmit { focusState.wrappedValue = .userEmailAddress }
                            .onAppear {
                                if viewModel.emailAddress.isBlank {
                                    focusState.wrappedValue = .authEmailAddress
                                }
                            }
                    }
                    .padding(.horizontal)
                }

                Text(t.t("~~Fill out your information"))
                    .fontHeader3()
                    .padding()

                UserInfoInputView(
                    languageOptions: $viewModel.languageOptions,
                    info: $viewModel.userInfo,
                    focusState: focusState
                )
                .padding(.horizontal)
                .disabled(disabled)
                .onAppear {
                    if !showEmailInput,
                       viewModel.userInfo.emailAddress.isBlank {
                        focusState.wrappedValue = .userEmailAddress
                    }
                }

                Group {
                    Text(t.t("requestAccess.request_will_be_sent"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        viewModel.onVolunteerWithOrg()
                    } label: {
                        BusyButtonContent(
                            isBusy: isRequestingInvite,
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
        .scrollDismissesKeyboard(.immediately)
    }
}
