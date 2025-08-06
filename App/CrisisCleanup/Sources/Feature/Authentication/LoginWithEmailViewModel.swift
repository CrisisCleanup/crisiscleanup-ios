import Combine
import SwiftUI

class LoginWithEmailViewModel: ObservableObject {
    private let appEnv: AppEnv
    let appSettings: AppSettingsProvider
    private let authApi: CrisisCleanupAuthApi
    private let dataApi: CrisisCleanupNetworkDataSource
    private let inputValidator: InputValidator
    private let accessTokenDecoder: AccessTokenDecoder
    private let accountDataRepository: AccountDataRepository
    private let accountEventBus: AccountEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    let isDebuggable: Bool

    @Published private(set) var viewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published private(set) var focusState: TextInputFocused?

    @Published private(set) var isAuthenticating: Bool = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        appEnv: AppEnv,
        appSettings: AppSettingsProvider,
        authApi: CrisisCleanupAuthApi,
        dataApi: CrisisCleanupNetworkDataSource,
        inputValidator: InputValidator,
        accessTokenDecoder: AccessTokenDecoder,
        accountDataRepository: AccountDataRepository,
        accountEventBus: AccountEventBus,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.appSettings = appSettings
        self.authApi = authApi
        self.dataApi = dataApi
        self.inputValidator = inputValidator
        self.accessTokenDecoder = accessTokenDecoder
        self.accountDataRepository = accountDataRepository
        self.accountEventBus = accountEventBus
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

            var errorMessage = ""

            do {
                guard let oauthResult = try await authApi.oauthLogin(emailAddress, password) else {
                    throw GenericError("OAuth fail")
                }

                let hasError = oauthResult.error?.isNotBlank == true
                if hasError {
                    errorMessage = translator.t("info.unknown_error")

                    logger.logError(GenericError("OAuth server error"))
                } else {
                    let refreshToken = oauthResult.refreshToken!
                    let accessToken = oauthResult.accessToken!

                    if let profile = await dataApi.getProfile(accessToken) {
                        let organization = profile.organization
                        if organization.isActive == false {
                            accountEventBus.onAccountInactiveOrganizations(profile.id)
                        } else {
                            accountDataRepository.setAccount(
                                profile,
                                refreshToken: refreshToken,
                                accessToken: accessToken,
                                expiresIn: oauthResult.expiresIn ?? 3600
                            )
                        }
                    }
                }
            } catch {
                errorMessage = "Unknown auth error".localizedString
            }

            let loginErrorMessage = errorMessage
            Task { @MainActor in
                errorMessage = loginErrorMessage
            }
        }
    }

    func logout() {
        accountEventBus.onLogout()
    }
}
