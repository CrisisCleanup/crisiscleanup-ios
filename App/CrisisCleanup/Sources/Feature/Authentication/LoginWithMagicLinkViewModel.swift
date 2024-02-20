import Combine
import SwiftUI

class LoginWithMagicLinkViewModel: ObservableObject {
    private let authApi: CrisisCleanupAuthApi
    private let dataApi: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    let authCode: String

    @Published var errorMessage: String = ""

    @Published private(set) var isAuthenticating: Bool = false
    @Published private(set) var isAuthenticateSuccessful: Bool = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        authApi: CrisisCleanupAuthApi,
        dataApi: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory,
        authCode: String
    ) {
        self.authApi = authApi
        self.dataApi = dataApi
        self.accountDataRepository = accountDataRepository
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
                    if emailAddress.isNotBlank && emailAddress != accountProfile.email {
                        message = translator.t("magicLink.log_out_before_different_account")

                        // TODO: Clear account data and support logging in with different email address?
                    } else {
                        let expirySeconds = Int64(Date().timeIntervalSince1970) + Int64(tokens.expiresIn)
                        accountDataRepository.setAccount(
                            refreshToken: tokens.refreshToken,
                            accessToken: tokens.accessToken,
                            id: accountProfile.id,
                            email: accountProfile.email,
                            firstName: accountProfile.firstName,
                            lastName: accountProfile.lastName,
                            expirySeconds: expirySeconds,
                            profilePictureUri: accountProfile.profilePicUrl ?? "",
                            org: OrgData(
                                id: accountProfile.organization.id,
                                name: accountProfile.organization.name
                            ),
                            hasAcceptedTerms: accountProfile.hasAcceptedTerms == true
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
            let isAuthenticationSuccessful = isSuccessful
            Task { @MainActor in
                self.errorMessage = errorMessage
                self.isAuthenticateSuccessful = isAuthenticationSuccessful
            }
        }
    }
}
