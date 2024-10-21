import Combine
import SwiftUI

class LoginWithMagicLinkViewModel: ObservableObject {
    private let authApi: CrisisCleanupAuthApi
    private let dataApi: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let accountEventBus: AccountEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    let authCode: String

    @Published var errorMessage: String = ""

    @Published private(set) var isAuthenticating: Bool = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        authApi: CrisisCleanupAuthApi,
        dataApi: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        accountEventBus: AccountEventBus,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory,
        authCode: String
    ) {
        self.authApi = authApi
        self.dataApi = dataApi
        self.accountDataRepository = accountDataRepository
        self.accountEventBus = accountEventBus
        self.translator = translator
        logger = loggerFactory.getLogger("auth")
        self.authCode = authCode
    }

    func onViewAppear() {
        subscribeAuthenticate()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeAuthenticate() {
        let magicLinkCode = authCode
        if magicLinkCode.isBlank {
            errorMessage = translator.t("magicLink.invalid_link")
            return
        }

        guard !isAuthenticating else {
            return
        }
        isAuthenticating = true

        Task {
            var isSuccessful = false
            var message = ""
            do {
                defer {
                    Task { @MainActor in self.isAuthenticating = false }
                }

                if let tokens = try await self.authApi.magicLinkLogin(magicLinkCode),
                   let accountProfile = await dataApi.getProfile(tokens.accessToken) {
                    let accountData = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst()
                    let emailAddress = accountData.emailAddress
                    if emailAddress.isNotBlank &&
                        emailAddress.lowercased() != accountProfile.email.lowercased() {
                        message = translator.t("magicLink.log_out_before_different_account")

                        // TODO: Clear account data and support logging in with different email address?
                    } else if(accountProfile.organization.isActive == false) {
                        accountEventBus.onAccountInactiveOrganizations(accountProfile.id)
                    } else {
                        accountDataRepository.setAccount(
                            accountProfile,
                            refreshToken: tokens.refreshToken,
                            accessToken: tokens.accessToken,
                            expiresIn: tokens.expiresIn
                        )
                        isSuccessful = true
                    }
                }
            } catch {
                logger.logError(error)
            }

            if !isSuccessful,
               errorMessage.isBlank {
                message = translator.t("magicLink.login_failed_try_again")
            }

            let errorMessage = message
            Task { @MainActor in
                self.errorMessage = errorMessage
            }
        }
    }
}
