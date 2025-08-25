import Combine
import SwiftUI

class RequestOrgAccessViewModel: ObservableObject {
    private let languageRepository: LanguageTranslationsRepository
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let accountUpdateRepository: AccountUpdateRepository
    private let accountDataRepository: AccountDataRepository
    private let inputValidator: InputValidator
    private let accountEventBus: AccountEventBus
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    @Published var screenTitle = ""

    internal let showEmailInput: Bool
    @Published var emailAddress = ""
    @Published var emailAddressError = ""

    internal let invitationCode: String

    @Published var userInfo = UserInfoInputData()

    @Published var errorFocus: TextInputFocused?

    private let isFetchingInviteInfoSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isFetchingInviteInfo = false
    private let inviteDisplaySubject = CurrentValueSubject<InviteDisplayInfo?, Never>(nil)
    @Published var inviteDisplay: InviteDisplayInfo?

    private let inviteInfoErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var inviteInfoErrorMessage = ""

    private let isPullingLanguageOptions = CurrentValueSubject<Bool, Never>(false)
    private let languageOptionsSubject = CurrentValueSubject<[LanguageIdName], Never>([])
    @Published var languageOptions = [LanguageIdName]()

    private let isRequestingInviteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var isRequestingInvite = false

    @Published private(set) var wasAuthenticated = false

    let transferOrgOptions = [
        TransferOrgOption.users,
        .all,
        .doNotTransfer,
    ]
    @Published private(set) var transferOrgErrorMessage = ""
    private let isTransferringOrgSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isTransferringOrg = false
    @Published private(set) var isOrgTransferred = false

    @Published private(set) var isLoading = false

    private let requestedOrgSubject = CurrentValueSubject<InvitationRequestResult?, Never>(nil)
    @Published private(set) var isInviteRequested = false
    @Published private(set) var requestSentTitle = ""
    @Published private(set) var requestSentText = ""

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        languageRepository: LanguageTranslationsRepository,
        orgVolunteerRepository: OrgVolunteerRepository,
        accountUpdateRepository: AccountUpdateRepository,
        accountDataRepository: AccountDataRepository,
        inputValidator: InputValidator,
        accountEventBus: AccountEventBus,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory,
        showEmailInput: Bool = false,
        invitationCode: String = "",
    ) {
        self.languageRepository = languageRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.accountUpdateRepository = accountUpdateRepository
        self.accountDataRepository = accountDataRepository
        self.inputValidator = inputValidator
        self.translator = translator
        self.accountEventBus = accountEventBus
        logger = loggerFactory.getLogger("org-invite")

        self.showEmailInput = showEmailInput
        self.invitationCode = invitationCode
    }

    func onViewAppear() {
        subscribeScreenTitle()
        subscribeLoadingEditable()
        subscribeLanguageOptions()
        subscribeInviteInfo()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeScreenTitle() {
        Publishers.CombineLatest(
            requestedOrgSubject,
            $inviteDisplay,
        )
        .map {(org, invite) in
            let key = if org == nil {
                invite?.inviteInfo.isExistingUser == true ? "actions.transfer" : "actions.sign_up"

            } else {
                "actions.request_access"
            }
            return self.translator.t(key)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.screenTitle, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeLoadingEditable() {
        isFetchingInviteInfoSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isFetchingInviteInfo, on: self)
            .store(in: &subscriptions)

        isRequestingInviteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRequestingInvite, on: self)
            .store(in: &subscriptions)

        isTransferringOrgSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isTransferringOrg, on: self)
            .store(in: &subscriptions)

        let isStateTransient = Publishers.CombineLatest3(
            $isFetchingInviteInfo,
            $isRequestingInvite,
            $isTransferringOrg,
        )
            .map { b0, b1, b2 in b0 || b1 || b2 }
            .removeDuplicates()
            .replay1()

        Publishers.CombineLatest(
            isPullingLanguageOptions,
            isStateTransient,
        )
        .map { b0, b1 in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &subscriptions)

        isStateTransient
            .receive(on: RunLoop.main)
            .sink { isBusy in
                self.editableViewState.isEditable = !isBusy
            }
            .store(in: &subscriptions)

        requestedOrgSubject
            .receive(on: RunLoop.main)
            .sink(receiveValue: { result in
                if let result = result {
                    let t = self.translator
                    if result.isNewAccountRequest {
                        var title = t.t("info.success")
                        var message = t.t("invitationSignup.success_accept_invitation")
                        if self.showEmailInput {
                            title = t.t("requestAccess.request_sent")
                            message = t.t("requestAccess.request_sent_to_org")
                                .replacingOccurrences(of: "{organization}", with: result.organizationName)
                                .replacingOccurrences(of: "{requested_to}", with: result.organizationRecipient)
                        }
                        self.requestSentTitle = title
                        self.requestSentText = message
                    } else {
                        self.inviteInfoErrorMessageSubject.value = t.t("requestAccess.already_in_org_error")
                    }
                }

                self.isInviteRequested = result?.isNewAccountRequest == true
            })
            .store(in: &subscriptions)
    }

    private func subscribeLanguageOptions() {
        languageOptionsSubject
            .receive(on: RunLoop.main)
            .sink(receiveValue: { options in
                self.languageOptions = options
                if options.isNotEmpty,
                   self.userInfo.language.name.isBlank {
                    let recommended = self.languageRepository.getRecommendedLanguage(options)
                    self.userInfo.language = recommended!
                }
            })
            .store(in: &subscriptions)

        if languageOptions.isEmpty,
           !isPullingLanguageOptions.value {
            isPullingLanguageOptions.value = true
            Task {
                do {
                    defer { isPullingLanguageOptions.value = false }
                    languageOptionsSubject.value = await languageRepository.getLanguageOptions()
                }
            }
        }
    }

    private func subscribeInviteInfo() {
        inviteInfoErrorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.inviteInfoErrorMessage, on: self)
            .store(in: &subscriptions)
        inviteInfoErrorMessageSubject.value = ""

        if showEmailInput ||
            invitationCode.isBlank {
            return
        }

        inviteDisplaySubject
            .receive(on: RunLoop.main)
            .assign(to: \.inviteDisplay, on: self)
            .store(in: &subscriptions)

        isFetchingInviteInfoSubject.value = true
        Task {
            defer {
                isFetchingInviteInfoSubject.value = false
            }

            if let inviteInfo = await orgVolunteerRepository.getInvitationInfo(invitationCode) {
                if inviteInfo.isExpiredInvite {
                    inviteInfoErrorMessageSubject.value = translator.t("requestAccess.invite_expired_try_again")
                } else {
                    inviteDisplaySubject.value = InviteDisplayInfo(
                        inviteInfo: inviteInfo,
                        inviteMessage: translator.t("requestAccess.invited_you_to_join_org")
                            .replacingOccurrences(of: "{email}", with: inviteInfo.invitedEmail)
                            .replacingOccurrences(of: "{organization}", with: inviteInfo.orgName)
                    )

                    if userInfo.emailAddress.isBlank {
                        Task { @MainActor in
                            userInfo.emailAddress = inviteInfo.invitedEmail
                        }
                    }
                }
            } else {
                inviteInfoErrorMessageSubject.value = translator.t("requestAccess.invite_error")
            }
        }
    }

    private func clearErrors() {
        errorFocus = nil
        emailAddressError = ""
        userInfo.clearErrors()
    }

    func onVolunteerWithOrg() {
        clearErrors()

        var errorFocuses = [TextInputFocused]()

        if showEmailInput,
           !inputValidator.validateEmailAddress(emailAddress) {
            emailAddressError = translator.t("invitationSignup.email_error")
            errorFocuses.append(.authEmailAddress)
        }

        errorFocuses.append(contentsOf: userInfo.validateInput(inputValidator, translator))

        errorFocus = errorFocuses.first
        if errorFocus != nil ||
            // TODO: Default to US English when blank rather than silently exiting
            userInfo.language.name.isBlank {
            return
        }

        if isRequestingInviteSubject.value {
            return
        }
        isRequestingInviteSubject.value = true
        Task {
            do {
                defer {
                    isRequestingInviteSubject.value = false
                }

                if showEmailInput {
                    requestedOrgSubject.value = await orgVolunteerRepository.requestInvitation(
                        InvitationRequest(
                            firstName: userInfo.firstName,
                            lastName: userInfo.lastName,
                            emailAddress: userInfo.emailAddress,
                            title: userInfo.title,
                            password: userInfo.password,
                            mobile: userInfo.phone,
                            languageId: userInfo.language.id,
                            inviterEmailAddress: emailAddress
                        )
                    )
                } else if invitationCode.isNotBlank {
                    // TODO: Test success and account already exists
                    let inviteResult = await self.orgVolunteerRepository.acceptInvitation(
                        CodeInviteAccept(
                            firstName: userInfo.firstName,
                            lastName: userInfo.lastName,
                            emailAddress: userInfo.emailAddress,
                            title: userInfo.title,
                            password: userInfo.password,
                            mobile: userInfo.phone,
                            languageId: userInfo.language.id,
                            invitationCode: invitationCode
                        )
                    )
                    if inviteResult == .success {
                        let inviteInfo = inviteDisplay?.inviteInfo
                        let orgName = inviteInfo?.orgName ?? ""
                        requestedOrgSubject.value = InvitationRequestResult(
                            organizationName: orgName,
                            organizationRecipient: inviteInfo?.inviterEmail ?? "",
                            isNewAccountRequest: orgName.isNotBlank
                        )
                    } else {
                        var errorMessageTranslateKey = "requestAccess.join_org_error"
                        if invitationCode.isBlank,
                           inviteDisplay?.inviteInfo.expiration.isPast == true {
                            errorMessageTranslateKey = "requestAccess.invite_expired_try_again"
                        }
                        inviteInfoErrorMessageSubject.value = translator.t(errorMessageTranslateKey)
                    }
                }
            }
        }
    }

    func onChangeTransferOrgOption() {
        transferOrgErrorMessage = ""
    }

    func onTransferOrg(_ selectedOrgTransfer: TransferOrgOption) {
        switch selectedOrgTransfer {
        case .users,
                .all:
            guard !isTransferringOrgSubject.value else {
                return
            }
            isTransferringOrgSubject.value = true
            let action = selectedOrgTransfer == .users ? ChangeOrganizationAction.users : .all
            Task {
                do {
                    defer {
                        isTransferringOrgSubject.value = false
                    }

                    try await transferToOrg(action)
                } catch {
                    logger.logError(error)
                }
            }

        default: break
        }
    }

    private func transferToOrg(_ action: ChangeOrganizationAction) async throws {
        let isAuthenticatedPublisher = accountDataRepository.isAuthenticated.eraseToAnyPublisher()
        let isAuthenticated = try await isAuthenticatedPublisher.asyncFirst()

        let isTransferred = await accountUpdateRepository.acceptOrganizationChange(action, invitationCode)

        Task { @MainActor in
            if isTransferred {
                isOrgTransferred = true

                if isAuthenticated {
                    wasAuthenticated = true
                    accountEventBus.onLogout()
                }
            } else {
                logger.logError(GenericError("User transfer to org failed."))
                transferOrgErrorMessage = translator.t("~~There was an issue during organization transfer. Try again later or reach out to support for help.")
            }
        }
    }
}

struct InviteDisplayInfo: Equatable {
    let inviteInfo: OrgUserInviteInfo
    let inviteMessage: String

    var avatarUrl: URL? { inviteInfo.inviterAvatarUrl }
    var isSvgAvatar: Bool { avatarUrl?.lastPathComponent.hasSuffix(".svg") == true }
    var displayName: String { inviteInfo.displayName }
}

enum TransferOrgOption {
    case notSelected,
         users,
         all,
         doNotTransfer

    var translateKey: String {
        switch self {
        case .notSelected:
            return ""
        case .users:
            return "invitationSignup.yes_transfer_just_me"
        case .all:
            return "invitationSignup.yes_transfer_me_and_cases"
        case .doNotTransfer:
            return "invitationSignup.no_transfer"
        }
    }
}
