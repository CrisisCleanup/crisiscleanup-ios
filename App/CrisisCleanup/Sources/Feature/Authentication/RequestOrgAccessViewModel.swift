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
    internal let invitingUserId: Int64

    @Published var userInfo = UserInfoInputData()

    @Published var errorFocus: TextInputFocused?

    private let isFetchingInviteInfoSubject = CurrentValueSubject<Bool, Never>(false)
    @Published var isFetchingInviteInfo = false
    private let orgUserInviteInfoSubject = CurrentValueSubject<InviterText?, Never>(nil)
    @Published var orgUserInviteInfo: InviterText?

    private let inviteInfoErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published var inviteInfoErrorMessage = ""

    private let isPullingLanguageOptions = CurrentValueSubject<Bool, Never>(false)
    private let languageOptionsSubject = CurrentValueSubject<[LanguageIdName], Never>([])
    @Published var languageOptions = [LanguageIdName]()

    private let isRequestingInviteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published var isRequestingInvite = false

    @Published var isLoading = false

    private let requestedOrgSubject = CurrentValueSubject<InvitationRequestResult?, Never>(nil)
    @Published var isInviteRequested = false
    @Published var requestSentTitle = ""
    @Published var requestSentText = ""

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        languageRepository: LanguageTranslationsRepository,
        orgVolunteerRepository: OrgVolunteerRepository,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        showEmailInput: Bool = false,
        invitationCode: String = "",
        invitingUserId: Int64 = 0
    ) {
        self.languageRepository = languageRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.inputValidator = inputValidator
        self.translator = translator

        self.showEmailInput = showEmailInput
        self.invitationCode = invitationCode
        self.invitingUserId = invitingUserId
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
                let key = $0 == nil ? "~~Signup" : "nav.request_access"
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
                self.isInviteRequested = result != nil

                if let result = result {
                    let t = self.translator
                    self.requestSentTitle = t.t("~~Your request has been sent")
                    self.requestSentText = t.t("requestAccess.request_sent_to_org")
                        .replacingOccurrences(of: "{organization}", with: result.organizationName)
                        .replacingOccurrences(of: "{requested_to}", with: result.organizationRecipient)
                }
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
        if showEmailInput ||
            invitationCode.isBlank {
            return
        }

        orgUserInviteInfoSubject
            .receive(on: RunLoop.main)
            .assign(to: \.orgUserInviteInfo, on: self)
            .store(in: &subscriptions)

        inviteInfoErrorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.inviteInfoErrorMessage, on: self)
            .store(in: &subscriptions)

        isFetchingInviteInfoSubject.value = true

        inviteInfoErrorMessageSubject.value = ""

        Task {
            defer {
                isFetchingInviteInfoSubject.value = false
            }

            if let inviteInfo = await orgVolunteerRepository.getInvitationInfo(invitationCode) {
                if inviteInfo.isExpiredInvite {
                    inviteInfoErrorMessageSubject.value = translator.t("~~This invite has expired. Ask for new invite or try a different invitation method.")
                } else {
                    orgUserInviteInfoSubject.value = InviterText(
                        inviteInfo: inviteInfo,
                        inviteMessage: translator.t("~~invited you ({email}) to join {organization}.")
                            .replacingOccurrences(of: "{email}", with: inviteInfo.invitedEmail)
                            .replacingOccurrences(of: "{organization}", with: inviteInfo.orgName)
                    )
                }
            } else {
                inviteInfoErrorMessageSubject.value = translator.t("~~There was a problem with invites. Try again later, ask for a new invite, or try a different invitation method.")
            }
        }
    }

    private func clearErrors() {
        errorFocus = nil
        emailAddressError = ""
        userInfo.emailAddressError = ""
        userInfo.firstNameError = ""
        userInfo.lastNameError = ""
        userInfo.phoneError = ""
        userInfo.passwordError = ""
        userInfo.confirmPasswordError = ""
    }

    func onVolunteerWithOrg() {
        clearErrors()

        var errorFocuses = [TextInputFocused]()

        if showEmailInput,
           !inputValidator.validateEmailAddress(emailAddress) {
            emailAddressError = translator.t("invitationSignup.email_error")
            errorFocuses.append(.authEmailAddress)
        }

        if !inputValidator.validateEmailAddress(userInfo.emailAddress) {
            userInfo.emailAddressError = translator.t("invitationSignup.email_error")
            errorFocuses.append(.userEmailAddress)
        }
        if userInfo.password.trim().count < 8 {
            userInfo.passwordError = translator.t("invitationSignup.password_length_error")
            errorFocuses.append(.userPassword)
        }
        if userInfo.password != userInfo.confirmPassword {
            userInfo.confirmPasswordError = translator.t("invitationSignup.password_match_error")
            errorFocuses.append(.userConfirmPassword)
        }
        if userInfo.phone.isBlank {
            userInfo.phoneError = translator.t("invitationSignup.mobile_error")
            errorFocuses.append(.userPhone)
        }

        errorFocus = errorFocuses.first
        if errorFocus != nil ||
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
                    // TODO: Test
                    self.requestedOrgSubject.value = await self.orgVolunteerRepository.requestInvitation(
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
                    // TODO: Test
                    let isRequested = await self.orgVolunteerRepository.acceptInvitation(
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
                    if isRequested {
                        let inviteInfo = orgUserInviteInfo?.inviteInfo
                        self.requestedOrgSubject.value = InvitationRequestResult(
                            organizationName: inviteInfo?.orgName ?? "",
                            organizationRecipient: inviteInfo?.inviterEmail ?? ""
                        )
                    } else {
                        // TODO: Show error message
                        // TODO: Also handle case where code was not expired when opened but expired on submit
                    }
                }
            }
        }
    }
}

struct InviterText: Equatable {
    let inviteInfo: OrgUserInviteInfo
    let inviteMessage: String

    var avatarUrl: URL? { inviteInfo.inviterAvatarUrl }
    var isSvgAvatar: Bool { avatarUrl?.lastPathComponent.hasSuffix(".svg") == true }
    var displayName: String { inviteInfo.displayName }
}
