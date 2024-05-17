import Combine
import SwiftUI

class LoginWithEmailViewModel: ObservableObject {
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

    @Published private(set) var viewData: AuthenticateViewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published private(set) var focusState: TextInputFocused?

    @Published private(set) var isAuthenticating: Bool = false
    @Published private(set) var isAuthenticateSuccessful: Bool = false

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
            .map {
                AuthenticateViewData(
                    state: .ready,
                    accountData: $0
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.viewData, on: self)
            .store(in: &subscriptions)
    }

    private func resetVisualState() {
        errorMessage = ""
        focusState = nil
    }

    private func validateInput(_ emailAddress: String, _ password: String) -> Bool {
        if emailAddress.isBlank {
            errorMessage = translator.t("invitationSignup.email_error")
            focusState = .authEmailAddress
            return false
        }

        if !inputValidator.validateEmailAddress(emailAddress) {
            errorMessage = translator.translate("invitationSignup.invalid_email_error", "Enter valid email error")
            focusState = .authEmailAddress
            return false
        }

        if password.isBlank {
            errorMessage = translator.t("invitationSignup.password_length_error")
            focusState = .authPassword
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
            guard let oauthResult = try await authApi.oauthLogin(emailAddress, password) else { throw GenericError("OAuth fail") }

            let hasError = result.errors?.isNotEmpty == true || oauthResult.error?.isNotBlank == true
            if hasError {
                let loginError = result.errors?.condenseMessages
                if loginError == "Unable to log in with provided credentials." {
                    errorMessage = translator.t("loginForm.invalid_credentials_msg")
                } else {
                    let logErrorMessage = [
                        loginError,
                        oauthResult.error,
                    ]
                        .combineTrimText("\n")
                        .ifBlank { "Server error" }
                    logger.logError(GenericError(logErrorMessage))
                }
            } else {
                let refreshToken = oauthResult.refreshToken!
                let accessToken = oauthResult.accessToken!
                let expirySeconds = Int64(Date().timeIntervalSince1970) + Int64(oauthResult.expiresIn!)

                let claims = result.claims!
                let profilePicUri = claims.files?.profilePictureUrl ?? ""

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
                    refreshToken: refreshToken,
                    accessToken: accessToken,
                    expirySeconds: expirySeconds
                )
                return LoginResult(errorMessage: "", success: success)
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
        if !validateInput(emailAddress, password) {
            return
        }

        if isAuthenticating {
            return
        }
        isAuthenticating = true

        resetVisualState()

        Task {
            defer {
                Task { @MainActor in isAuthenticating = false }
            }

            let loginResult = await authenticateAsync(emailAddress, password)
            if let result = loginResult.success {
                with(result) { r in
                    accountDataRepository.setAccount(
                        refreshToken: r.refreshToken,
                        accessToken: r.accessToken,
                        id: r.claims.id,
                        email: r.claims.email,
                        firstName: r.claims.firstName,
                        lastName: r.claims.lastName,
                        expirySeconds: r.expirySeconds,
                        profilePictureUri: r.profilePictureUri,
                        org: r.orgData,
                        hasAcceptedTerms: r.claims.hasAcceptedTerms == true,
                        activeRoles: r.claims.activeRoles
                    )
                }

                Task { @MainActor in self.isAuthenticateSuccessful = true }
            } else {
                Task { @MainActor in
                    errorMessage = loginResult.errorMessage
                }
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
    let refreshToken: String
    let accessToken: String
    let expirySeconds: Int64
}

fileprivate struct LoginResult {
    let errorMessage: String
    let success: LoginSuccess?
}
