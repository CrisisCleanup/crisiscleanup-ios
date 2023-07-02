import Combine
import SwiftUI

class AuthenticateViewModel: ObservableObject {
    private let appEnv: AppEnv
    let appSettings: AppSettingsProvider
    private let authApi: CrisisCleanupAuthApi
    private let inputValidator: InputValidator
    private let accessTokenDecoder: AccessTokenDecoder
    private let accountDataRepository: AccountDataRepository
    private let authEventBus: AuthEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    let isDebuggable: Bool

    @Published var viewData: AuthenticateViewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published var passwordHasFocus: Bool = false
    @Published var emailHasFocus: Bool = false

    @Published var isAuthenticating: Bool = false
    @Published var isAuthenticateSuccessful: Bool = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        appEnv: AppEnv,
        appSettings: AppSettingsProvider,
        authApi: CrisisCleanupAuthApi,
        inputValidator: InputValidator,
        accessTokenDecoder: AccessTokenDecoder,
        accountDataRepository: AccountDataRepository,
        authEventBus: AuthEventBus,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.appSettings = appSettings
        self.authApi = authApi
        self.inputValidator = inputValidator
        self.accessTokenDecoder = accessTokenDecoder
        self.accountDataRepository = accountDataRepository
        self.authEventBus = authEventBus
        self.translator = translator
        logger = loggerFactory.getLogger("auth")

        isDebuggable = appEnv.isDebuggable
    }

    func onViewAppear() {
        subscribeAccountData()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { data in
                self.viewData = AuthenticateViewData(
                    state: .ready,
                    accountData: data
                )
            }
            .store(in: &subscriptions)
    }

    private func resetVisualState() {
        errorMessage = ""
        emailHasFocus = false
        passwordHasFocus = false
    }

    private func validateInput(_ emailAddress: String, _ password: String) -> Bool {
        if emailAddress.isBlank {
            errorMessage = translator("invitationSignup.email_error")
            emailHasFocus = true
            return false
        }

        if !inputValidator.validateEmailAddress(emailAddress) {
            errorMessage = translator.translate("invitationSignup.invalid_email_error", "Enter valid email error")
            emailHasFocus = true
            return false
        }

        if password.isBlank {
            errorMessage = translator("invitationSignup.password_length_error")
            passwordHasFocus = true
            return false
        }

        return true
    }

    private func authenticateAsync(
        _ emailAddress: String,
        _ password: String
    ) async -> LoginResult {
        var errorMessage = ""

        do {
            guard let result = try await authApi.login(emailAddress, password) else {
                throw GenericError("Server not found")
            }
            let hasError = result.errors?.isNotEmpty == true
            if hasError {
                let logErrorMessage = result.errors?.condenseMessages ?? "Server error"
                if logErrorMessage == "Unable to log in with provided credentials." {
                    errorMessage = translator("loginForm.invalid_credentials_msg")
                } else {
                    logger.logError(GenericError(logErrorMessage))
                }
            } else {
                let accessToken = result.accessToken!

                let expirySeconds = try Int64(accessTokenDecoder.decode(accessToken).expiresAt.timeIntervalSince1970)

                let claims = result.claims!
                let profilePicUri = claims.files?.filter { $0.isProfilePicture }.firstOrNil?.largeThumbnailUrl ?? ""

                let organization = result.organizations
                var orgData = emptyOrgData
                if organization?.isActive == true &&
                    organization!.id >= 0 &&
                    organization!.name.isNotBlank {
                    orgData = OrgData(
                        id: organization!.id,
                        name: organization!.name
                    )
                }

                let success = LoginSuccess(
                    claims: claims,
                    orgData: orgData,
                    profilePictureUri: profilePicUri,
                    accessToken: accessToken,
                    expirySeconds: expirySeconds
                )
                return LoginResult(errorMessage: "", success: success   )
            }
        } catch {
            errorMessage = "Unknown auth error".localizedString
        }

        return LoginResult(
            errorMessage: errorMessage,
            success: nil
        )
    }

    func authenticate(_ emailAddress: String, _ password: String) {
        if isAuthenticating {
            return
        }

        resetVisualState()

        if !validateInput(emailAddress, password) {
            return
        }

        isAuthenticating = true
        Task {
            defer {
                Task { @MainActor in isAuthenticating = false }
            }

            let loginResult = await authenticateAsync(emailAddress, password)
            if let result = loginResult.success {
                with(result) { r in
                    accountDataRepository.setAccount(
                        id: r.claims.id,
                        accessToken: r.accessToken,
                        email: r.claims.email,
                        firstName: r.claims.firstName,
                        lastName: r.claims.lastName,
                        expirySeconds: r.expirySeconds,
                        profilePictureUri: r.profilePictureUri,
                        org: r.orgData
                    )
                }

                Task { @MainActor in self.isAuthenticateSuccessful = true }
            } else {
                errorMessage = loginResult.errorMessage
            }
        }
    }

    func logout() {
        authEventBus.onLogout()
    }
}

fileprivate struct LoginSuccess {
    let claims: NetworkAuthUserClaims
    let orgData: OrgData
    let profilePictureUri: String
    let accessToken: String
    let expirySeconds: Int64
}

fileprivate struct LoginResult {
    let errorMessage: String
    let success: LoginSuccess?
}
