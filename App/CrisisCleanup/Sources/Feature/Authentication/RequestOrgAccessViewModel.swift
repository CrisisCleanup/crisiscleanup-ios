import Combine
import SwiftUI

class RequestOrgAccessViewModel: ObservableObject {
    private let languageRepository: LanguageTranslationsRepository
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator

    @Published var screenTitle = ""

    let showEmailInput: Bool
    @Published var emailAddress = ""
    @Published var emailAddressError = ""

    @Published var userInfo = UserInfoInputData()

    @Published var errorFocus: TextInputFocused?

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
        showEmailInput: Bool = false
    ) {
        self.languageRepository = languageRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.inputValidator = inputValidator
        self.translator = translator

        self.showEmailInput = showEmailInput
    }

    func onViewAppear() {
        subscribeScreenTitle()
        subscribeLoading()
        subscribeLanguageOptions()
        subscribeEditableState()
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
        isRequestingInviteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRequestingInvite, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            isPullingLanguageOptions,
            $isRequestingInvite
        )
        .map { b0, b1 in b0 || b1 }
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
        $isRequestingInvite
            .receive(on: RunLoop.main)
            .sink(receiveValue: { isRequesting in
                self.editableViewState.isEditable = !isRequesting
            })
            .store(in: &subscriptions)
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
            }
        }
    }
}
