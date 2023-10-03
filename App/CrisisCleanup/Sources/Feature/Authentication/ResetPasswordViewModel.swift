import Combine
import SwiftUI

class ResetPasswordViewModel: ObservableObject {
    private let resetPasswordToken: String

    private let accountUpdateRepository: AccountUpdateRepository
    private let translator: KeyAssetTranslator

    @Published var password = ""
    @Published var confirmPassword = ""

    @Published var resetPasswordErrorMessage = ""
    @Published var resetPasswordConfirmErrorMessage = ""

    private let isResettingPasswordSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isResettingPassword = false

    private let isPasswordResetSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isPasswordReset = false

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        resetPasswordToken: String,
        accountUpdateRepository: AccountUpdateRepository,
        translator: KeyAssetTranslator
    ) {
        self.resetPasswordToken = resetPasswordToken
        self.accountUpdateRepository = accountUpdateRepository
        self.translator = translator
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeEditableState()
        subscribeResetState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        isResettingPasswordSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isResettingPassword, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeEditableState() {
        $isResettingPassword
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)
    }

    private func subscribeResetState() {
        isPasswordResetSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isPasswordReset, on: self)
            .store(in: &subscriptions)
    }

    private func clearResetPasswordErrors() {
        resetPasswordErrorMessage = ""
        resetPasswordConfirmErrorMessage = ""
    }

    private func clearState() {
        password = ""
        confirmPassword = ""
    }

    func onResetPassword() {
        let resetToken = resetPasswordToken
        if resetToken.isBlank {
            return
        }

        clearResetPasswordErrors()

        let pw = password
        let confirmPw = confirmPassword

        if (pw.trim().count < 8) {
            resetPasswordErrorMessage = translator.t("invitationSignup.password_length_error")
            return
        }
        if (pw != confirmPw) {
            resetPasswordConfirmErrorMessage = translator.t("resetPassword.mismatch_passwords_try_again")
            return
        }

        isResettingPasswordSubject.value = true
        Task {
            do {
                defer {
                    isResettingPasswordSubject.value = false
                }

                let isChanged = await accountUpdateRepository.changePassword(
                    password: pw,
                    token: resetToken
                )

                Task { @MainActor in
                    if (isChanged) {
                        isPasswordResetSubject.value = true
                        clearState()
                    } else {
                        resetPasswordErrorMessage = translator.t("info.reset_password_error")
                    }
                }
            }
        }
    }
}
