import Combine
import Foundation

class PersistentInviteViewModel: ObservableObject {
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let languageRepository: LanguageTranslationsRepository
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator

    internal let invite: UserPersistentInvite

    @Published private(set) var isLoading = false

    @Published var userInfo = UserInfoInputData()

    @Published var errorFocus: TextInputFocused?

    @Published var inviteDisplay: InviteDisplayInfo? = nil

    private let isPullingLanguageOptions = CurrentValueSubject<Bool, Never>(false)
    private let languageOptionsSubject = CurrentValueSubject<[LanguageIdName], Never>([])
    @Published var languageOptions = [LanguageIdName]()

    private let isJoiningOrgSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isJoiningOrg = false
    @Published private(set) var joinResultMessage = ""

    private let isInviteAcceptedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isInviteAccepted = false
    @Published private(set) var acceptedTitle = ""

    private let inviteFailMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var inviteFailMessage = ""

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        orgVolunteerRepository: OrgVolunteerRepository,
        languageRepository: LanguageTranslationsRepository,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        invite: UserPersistentInvite
    ) {
        self.orgVolunteerRepository = orgVolunteerRepository
        self.languageRepository = languageRepository
        self.inputValidator = inputValidator
        self.translator = translator

        self.invite = invite
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeLanguageOptions()
        subscribeTokenValidation()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        Publishers.CombineLatest(
            $inviteDisplay,
            $isJoiningOrg
        )
        .map { (info, b1) in info == nil || b1 }
        .receive(on: RunLoop.main)
        .sink { isLoading in
            self.isLoading = isLoading
            self.editableViewState.isEditable = !isLoading
        }
        .store(in: &subscriptions)

        isJoiningOrgSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isJoiningOrg, on: self)
            .store(in: &subscriptions)

        isInviteAcceptedSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isInviteAccepted, on: self)
            .store(in: &subscriptions)

        inviteFailMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.inviteFailMessage, on: self)
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

    private func subscribeTokenValidation() {
        guard !isJoiningOrgSubject.value else {
            return
        }
        isJoiningOrgSubject.value = true

        Task {
            do {
                defer {
                    isJoiningOrgSubject.value = false
                }

                let inviteInfo = await orgVolunteerRepository.getInvitationInfo(invite) ?? ExpiredNetworkOrgInvite
                let inviterText = InviteDisplayInfo(
                    inviteInfo: inviteInfo,
                    inviteMessage: translator.t("~~invites you to join {organization}.")
                        .replacingOccurrences(of: "{organization}", with: inviteInfo.orgName)
                )

                Task { @MainActor in
                    inviteDisplay = inviterText
                }
            }
        }
    }

    private func clearErrors() {
        errorFocus = nil
        userInfo.clearErrors()
    }

    func onVolunteerWithOrg() {
        clearErrors()

        let errorFocuses = userInfo.validateInput(inputValidator, translator)
        errorFocus = errorFocuses.first
        if errorFocus != nil ||
            // TODO: Default to US English when blank rather than silently exiting
            userInfo.language.name.isBlank {
            return
        }

        if isJoiningOrgSubject.value {
            return
        }
        isJoiningOrgSubject.value = true
        Task {
            do {
                defer {
                    isJoiningOrgSubject.value = false
                }

                // TODO: Test
                let joinResult = await orgVolunteerRepository.acceptPersistentInvitation(
                    CodeInviteAccept(
                        firstName: userInfo.firstName,
                        lastName: userInfo.lastName,
                        emailAddress: userInfo.emailAddress,
                        title: userInfo.title,
                        password: userInfo.password,
                        mobile: userInfo.phone,
                        languageId: userInfo.language.id,
                        invitationCode: invite.inviteToken
                    )
                )
                if joinResult == .success {
                    Task { @MainActor in
                        acceptedTitle = translator.t("~~Your account has been created")
                        isInviteAcceptedSubject.value = true
                    }
                } else {
                    var errorMessageTranslateKey = "~~There was an issue with joining the organization. Try logging in. If unable to login try joining again later."
                    switch joinResult {
                    case .redundant:
                        errorMessageTranslateKey = "~~You are in this organization."
                    default:
                        if inviteDisplay?.inviteInfo.expiration.isPast == true {
                            errorMessageTranslateKey = "~~The invite is expired. Request a new invite."
                        }
                    }
                    inviteFailMessageSubject.value = translator.t(errorMessageTranslateKey)
                }
            }
        }
    }
}
