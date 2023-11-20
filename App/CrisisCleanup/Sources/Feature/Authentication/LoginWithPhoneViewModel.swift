import Combine
import SwiftUI

class LoginWithPhoneViewModel: ObservableObject {
    private let appEnv: AppEnv
    let appSettings: AppSettingsProvider
    private let authApi: CrisisCleanupAuthApi
    private let inputValidator: InputValidator
    private let accessTokenDecoder: AccessTokenDecoder
    private let accountDataRepository: AccountDataRepository
    private let authEventBus: AuthEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    @Published private(set) var viewData: AuthenticateViewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published private(set) var focusState: TextInputFocused?

    private let isAcceptingCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isAcceptingCode = false

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
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeAccountData()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        isAcceptingCodeSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isAcceptingCode, on: self)
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
        // TODO: Validate
        //       Request phone code
        //       Show code input on successful code request or error otherwise
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
