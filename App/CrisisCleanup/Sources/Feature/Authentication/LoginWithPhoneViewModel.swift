import Combine
import SwiftUI

class LoginWithPhoneViewModel: ObservableObject {
    private let appEnv: AppEnv
    let appSettings: AppSettingsProvider
    private let authApi: CrisisCleanupAuthApi
    private let inputValidator: InputValidator
    private let accessTokenDecoder: AccessTokenDecoder
    private let accountUpdateRepository: AccountUpdateRepository
    private let accountDataRepository: AccountDataRepository
    private let authEventBus: AuthEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    @Published private(set) var viewData: AuthenticateViewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published private(set) var focusState: TextInputFocused?

    private let isRequestingCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRequestingCode = false
    @Published var openPhoneCodeLogin = false

    @Published private(set) var isAuthenticating: Bool = false
    @Published private(set) var isAuthenticateSuccessful: Bool = false

    private let numberRegex = #/^[\d -]+$/#

    private var subscriptions = Set<AnyCancellable>()

    init(
        appEnv: AppEnv,
        appSettings: AppSettingsProvider,
        authApi: CrisisCleanupAuthApi,
        inputValidator: InputValidator,
        accessTokenDecoder: AccessTokenDecoder,
        accountUpdateRepository: AccountUpdateRepository,
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
        self.accountUpdateRepository = accountUpdateRepository
        self.accountDataRepository = accountDataRepository
        self.authEventBus = authEventBus
        self.translator = translator
        logger = loggerFactory.getLogger("auth")
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeAccountData()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        isRequestingCodeSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRequestingCode, on: self)
            .store(in: &subscriptions)
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

    func requestPhoneCode(_ phoneNumber: String) {
        let trimPhoneNumber = phoneNumber.trim()
        guard ((try? numberRegex.wholeMatch(in: trimPhoneNumber) != nil) == true) else {
            errorMessage = translator.t("info.enter_valid_phone")
            return
        }

        guard !isRequestingCodeSubject.value else {
            return
        }
        isRequestingCodeSubject.value = true
        Task {
            do {
                defer { isRequestingCodeSubject.value = false }

                var isInitiated = false
                var message = ""

                if await accountUpdateRepository.initiatePhoneLogin(trimPhoneNumber) {
                    isInitiated = true
                } else {
                    // TODO: Be more specific
                    // TODO: Capture error and report to backend
                    message = translator.t("~~Phone number is invalid or phone login is down. Try again later.")
                }

                let openPhoneCodeLogin = isInitiated
                let errorMessage = message
                Task { @MainActor in
                    self.openPhoneCodeLogin = openPhoneCodeLogin
                    self.errorMessage = errorMessage
                }
            }
        }
    }

    func authenticate(_ code: String) {
        if isAuthenticating {
            return
        }
        isAuthenticating = true

        resetVisualState()

        Task {
            defer {
                Task { @MainActor in isAuthenticating = false }
            }
        }
    }
}

fileprivate struct LoginResult {
    let errorMessage: String
    let success: Bool
}
