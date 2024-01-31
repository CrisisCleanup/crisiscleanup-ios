import Combine
import SwiftUI

class RequestOrgAccessViewModel: ObservableObject {
    private let languageRepository: LanguageTranslationsRepository
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator

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
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        showEmailInput: Bool = false,
        invitationCode: String = ""
    ) {
        self.languageRepository = languageRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.inputValidator = inputValidator
        self.translator = translator

        self.showEmailInput = showEmailInput
        self.invitationCode = invitationCode
    }

    func onViewAppear() {
        subscribeScreenTitle()
        subscribeLoading()
        subscribeLanguageOptions()
        subscribeEditableState()
        subscribeInviteInfo()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeScreenTitle() {
        requestedOrgSubject
            .map {
                let key = $0 == nil ? "actions.sign_up" : "actions.request_access"
                return self.translator.t(key)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.screenTitle, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLoading() {
        isFetchingInviteInfoSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isFetchingInviteInfo, on: self)
            .store(in: &subscriptions)

        isRequestingInviteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRequestingInvite, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            isPullingLanguageOptions,
            $isFetchingInviteInfo,
            $isRequestingInvite
        )
        .map { b0, b1, b2 in b0 || b1 || b2 }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &subscriptions)

        requestedOrgSubject
            .receive(on: RunLoop.main)
            .sink(receiveValue: { result in
                if let result = result {
                    let t = self.translator
                    if result.isNewAccountRequest {
                        self.requestSentTitle = t.t("requestAccess.request_sent")
                        self.requestSentText = t.t("requestAccess.request_sent_to_org")
                            .replacingOccurrences(of: "{organization}", with: result.organizationName)
                            .replacingOccurrences(of: "{requested_to}", with: result.organizationRecipient)
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
                    self.userInfo.language = options.first!
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

    private func subscribeEditableState() {
        Publishers.CombineLatest(
            $isFetchingInviteInfo,
            $isRequestingInvite
        )
        .receive(on: RunLoop.main)
        .sink(receiveValue: { b0, b1 in
            self.editableViewState.isEditable = !(b0 || b1)
        })
        .store(in: &subscriptions)
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
}

struct InviteDisplayInfo: Equatable {
    let inviteInfo: OrgUserInviteInfo
    let inviteMessage: String

    var avatarUrl: URL? { inviteInfo.inviterAvatarUrl }
    var isSvgAvatar: Bool { avatarUrl?.lastPathComponent.hasSuffix(".svg") == true }
    var displayName: String { inviteInfo.displayName }
}
