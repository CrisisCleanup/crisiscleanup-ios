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
            errorMessage = translator.t("~~Magic link is invalid. Request another magic link.")
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
                        message = translator.t("~~Logging in with an account different from the currently signed in account is not supported. Logout of the signed in account first then login with a different account.")

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
                            )
                        )
                        isSuccessful = true
                    }
                }
            } catch {
                logger.logError(error)
            }

            if !isSuccessful,
               errorMessage.isBlank {
                message = translator.t("~~Login failed. Try requesting a new magic link.")
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
