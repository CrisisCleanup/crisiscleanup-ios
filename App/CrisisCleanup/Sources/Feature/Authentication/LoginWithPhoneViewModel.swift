import Combine
import SwiftUI

class LoginWithPhoneViewModel: ObservableObject {
    private let authApi: CrisisCleanupAuthApi
    private let dataApi: CrisisCleanupNetworkDataSource
    private let accountUpdateRepository: AccountUpdateRepository
    private let accountDataRepository: AccountDataRepository
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    let phoneNumber: String
    let obfuscatedPhoneNumber: String

    @Published private(set) var viewData: AuthenticateViewData = AuthenticateViewData()

    @Published var errorMessage: String = ""
    @Published private(set) var focusState: TextInputFocused?
    @Published private(set) var codeFocusState: SingleCodeFocused?

    private let isRequestingCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRequestingCode = false
    @Published var openPhoneCodeLogin = false

    private let isVerifyingCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var isVerifyingCode = false

    private var oneTimePasswordId: Int64 = 0
    private let accountOptionsSubject = CurrentValueSubject<[PhoneNumberAccount], Never>([])
    @Published private(set) var accountOptions = [PhoneNumberAccount]()
    private let isSelectAccountSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSelectAccount = false
    private let selectedAccountSubject = CurrentValueSubject<PhoneNumberAccount, Never>(PhoneNumberAccountNone)
    @Published var selectedAccount = PhoneNumberAccountNone

    @Published private(set) var isExchangingCode = false

    @Published private(set) var isAuthenticateSuccessful: Bool = false

    private let numberRegex = #/^[\d -]+$/#

    private var subscriptions = Set<AnyCancellable>()

    init(
        authApi: CrisisCleanupAuthApi,
        dataApi: CrisisCleanupNetworkDataSource,
        accountUpdateRepository: AccountUpdateRepository,
        accountDataRepository: AccountDataRepository,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory,
        phoneNumber: String
    ) {
        self.authApi = authApi
        self.dataApi = dataApi
        self.accountUpdateRepository = accountUpdateRepository
        self.accountDataRepository = accountDataRepository
        self.translator = translator
        logger = loggerFactory.getLogger("auth")

        let nonNumberRegex = #/[^\d]/#
        let phoneNumberNumbers = phoneNumber.replacing(nonNumberRegex, with: "")

        self.phoneNumber = phoneNumberNumbers
        // TODO: Refactor logic and test various strings
        obfuscatedPhoneNumber = {
            var s = phoneNumberNumbers
            if s.count > 4 {
                let startIndex = max(0, s.count - 4)
                let endIndex = s.count
                let lastFour = s.substring(startIndex, endIndex)
                let firstCount = s.count - 4
                func obfuscated(_ count: Int) -> String {
                    String(repeating: "•", count: count)
                }
                if firstCount > 3 {
                    let obfuscatedStart = obfuscated(firstCount - 3)
                    let obfuscatedMiddle = obfuscated(3)
                    s = "(\(obfuscatedStart)) \(obfuscatedMiddle) - \(lastFour)"
                } else {
                    let obfuscated = obfuscated(firstCount)
                    s = "\(obfuscated) - \(lastFour)"
                }
            }
            return s
        }()
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

        isVerifyingCodeSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isVerifyingCode, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $isRequestingCode,
            $isVerifyingCode
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isExchangingCode, on: self)
        .store(in: &subscriptions)

        selectedAccountSubject
            .receive(on: RunLoop.main)
            .assign(to: \.selectedAccount, on: self)
            .store(in: &subscriptions)

        accountOptionsSubject
            .receive(on: RunLoop.main)
            .assign(to: \.accountOptions, on: self)
            .store(in: &subscriptions)

        isSelectAccountSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSelectAccount, on: self)
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
        codeFocusState = nil
    }

    private func clearAccountSelect() {
        isSelectAccountSubject.value = false
        selectedAccountSubject.value = PhoneNumberAccountNone
        accountOptionsSubject.value = []
    }

    func requestPhoneCode(_ phoneNumber: String) {
        resetVisualState()
        clearAccountSelect()

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
                    message = translator.t("loginWithPhone.invalid_phone_unavailable_try_again")
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

    private func verifyPhoneCode(phoneNumber: String, code: String) async -> PhoneCodeVerification {
        if let result = await authApi.verifyPhoneCode(phoneNumber: phoneNumber, code: code),
           result.accounts.isNotEmpty {
            let accounts = result.accounts.map {
                PhoneNumberAccount(userId: $0.id, userDisplayName: $0.email, organizationName: $0.organizationName)
            }
            return PhoneCodeVerification(
                otpId: result.otpId,
                associatedAccounts: accounts,
                error: .none
            )
        }

        return PhoneCodeVerification(
            otpId: 0,
            associatedAccounts: [],
            error: .invalidCode
        )
    }

    func authenticate(_ code: String) {
        if isSelectAccount,
           selectedAccount.userId == 0 {
            errorMessage = translator.t("loginWithPhone.select_account")
            return
        }

        if accountOptions.isNotEmpty,
           accountOptions.first(where: { $0.userId == selectedAccount.userId }) == nil {
            selectedAccountSubject.value = PhoneNumberAccountNone
            isSelectAccountSubject.value = true
            errorMessage = translator.t("loginWithPhone.select_account")
            return
        }

        if isExchangingCode {
            return
        }
        isVerifyingCodeSubject.value = true

        resetVisualState()

        Task {
            defer {
                isVerifyingCodeSubject.value = false
            }

            var isSuccessful = false
            var message = ""

            if oneTimePasswordId == 0 {
                let result = await verifyPhoneCode(phoneNumber: phoneNumber, code: code)
                if result.associatedAccounts.isEmpty {
                    message = translator.t("loginWithPhone.no_account_error")
                } else {
                    oneTimePasswordId = result.otpId

                    // TODO: Test associated accounts
                    if result.associatedAccounts.count > 1 {
                        accountOptionsSubject.value = result.associatedAccounts
                        selectedAccountSubject.value = PhoneNumberAccountNone
                        isSelectAccountSubject.value = true
                    } else {
                        accountOptionsSubject.value = []
                        selectedAccountSubject.value = result.associatedAccounts.first!
                        isSelectAccountSubject.value = false
                    }
                }
            }

            let accountId = selectedAccountSubject.value.userId
            if accountId != 0,
               oneTimePasswordId != 0 {
                let accountData = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst()
                if let tokens = try await self.authApi.oneTimePasswordLogin(
                    accountId: accountId,
                    oneTimePasswordId: oneTimePasswordId
                ),
                   let accountProfile = await dataApi.getProfile(tokens.accessToken) {
                    let emailAddress = accountData.emailAddress
                    if emailAddress.isNotBlank,
                       emailAddress != accountProfile.email {
                        message = translator.t("loginWithPhone.log_out_before_different_account")

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
            }

            if !isSuccessful,
               errorMessage.isBlank {
                message = translator.t("loginWithPhone.login_failed_try_again")
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

fileprivate struct LoginResult {
    let errorMessage: String
    let success: Bool
}

struct PhoneNumberAccount {
    let userId: Int64
    let userDisplayName: String
    let organizationName: String

    var accountDisplay: String {
        userId > 0 ? "\(userDisplayName), \(organizationName)" : ""
    }
}

fileprivate let PhoneNumberAccountNone = PhoneNumberAccount(userId: 0, userDisplayName: "", organizationName: "")

fileprivate struct PhoneCodeVerification {
    let otpId: Int64
    let associatedAccounts: [PhoneNumberAccount]
    let error: OneTimePasswordError
}

fileprivate enum OneTimePasswordError {
    case none,
         invalidCode
}
