import Combine
import SwiftUI

class PasswordRecoverViewModel: ObservableObject {
    let showForgotPassword: Bool
    let showMagicLink: Bool

    private let accountDataRepository: AccountDataRepository
    private let accountUpdateRepository: AccountUpdateRepository
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator

    let screenTitleKey: String

    @Published private(set) var isLoadingAccountData = true
    @Published var emailAddress = ""

    @Published private(set) var forgotPasswordErrorMessage = ""
    @Published private(set) var magicLinkErrorMessage = ""

    @Published var password = ""
    @Published var confirmPassword = ""

    @Published private(set) var resetPasswordErrorMessage = ""
    @Published private(set) var resetPasswordConfirmErrorMessage = ""

    private let isInitiatingPasswordResetSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var isInitiatingPasswordReset = false
    private let isInitiatingMagicLinkSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var isInitiatingMagicLink = false

    @Published private(set) var isPasswordResetInitiated = false
    @Published private(set) var isMagicLinkInitiated = false

    let editableViewState = EditableView()

    @Published private(set) var isBusy = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        showForgotPassword: Bool,
        showMagicLink: Bool,
        accountDataRepository: AccountDataRepository,
        accountUpdateRepository: AccountUpdateRepository,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator
    ) {
        self.showForgotPassword = showForgotPassword
        self.showMagicLink = showMagicLink

        screenTitleKey = showForgotPassword ? "invitationSignup.forgot_password" : "nav.magic_link"

        self.accountDataRepository = accountDataRepository
        self.accountUpdateRepository = accountUpdateRepository
        self.inputValidator = inputValidator
        self.translator = translator
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeEditableState()
        subscribeAccountData()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        isInitiatingPasswordResetSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isInitiatingPasswordReset, on: self)
            .store(in: &subscriptions)

        isInitiatingMagicLinkSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isInitiatingMagicLink, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $isInitiatingPasswordReset,
            $isInitiatingMagicLink
        )
        .map { b0, b1 in b0 || b1 }
        .assign(to: \.isBusy, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeEditableState() {
        Publishers.CombineLatest(
            $isLoadingAccountData,
            $isBusy
        )
        .map { (b0, b1) in b0 || b1 }
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink {
                if (self.emailAddress.isBlank) {
                    self.emailAddress = $0.emailAddress
                }
                self.isLoadingAccountData = false
            }
            .store(in: &subscriptions)
    }

    func clearState() {
        password = ""
        confirmPassword = ""
    }

    func onInitiatePasswordReset() {
        forgotPasswordErrorMessage = ""

        let email = emailAddress.trim()
        if email.isBlank ||
            !inputValidator.validateEmailAddress(email)
        {
            forgotPasswordErrorMessage = translator.t("invitationSignup.email_error")
            return
        }

        if isInitiatingPasswordResetSubject.value {
            return
        }
        isInitiatingPasswordResetSubject.value = true
        Task {
            do {
                defer {
                    isInitiatingPasswordResetSubject.value = false
                }

                let result = await accountUpdateRepository.initiatePasswordReset(email)

                var isInitiated = false
                if let expiresAt = result.expiresAt,
                   expiresAt > Date.now {
                    isInitiated = true
                }

                let isResetInitiated = isInitiated
                Task { @MainActor in
                    if isResetInitiated {
                        isPasswordResetInitiated = true
                    } else {
                        forgotPasswordErrorMessage = result.errorMessage.ifBlank {
                            translator.t("info.reset_password_start_error")
                        }
                    }
                }
            }
        }
    }

    func onInitiateMagicLink() {
        magicLinkErrorMessage = ""

        let email = emailAddress.trim()
        if email.isBlank ||
            !inputValidator.validateEmailAddress(email)
        {
            magicLinkErrorMessage = translator.t("invitationSignup.email_error")
            return
        }

        if isInitiatingMagicLinkSubject.value {
            return
        }
        isInitiatingMagicLinkSubject.value = true
        Task {
            do {
                defer {
                    isInitiatingMagicLinkSubject.value = false
                }

                let isInitiated = await accountUpdateRepository.initiateEmailMagicLink(email)

                Task { @MainActor in
                    if (isInitiated) {
                        isMagicLinkInitiated = true
                    } else {
                        magicLinkErrorMessage = translator.t("info.magic_link_error")
                    }
                }
            }
        }
    }

    func clearResetPasswordErrors() {
        resetPasswordErrorMessage = ""
        resetPasswordConfirmErrorMessage = ""
    }
}
