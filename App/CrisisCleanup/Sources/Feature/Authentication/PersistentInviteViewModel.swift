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
        .assign(to: \.isLoading, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest(
            $isJoiningOrg,
            $isInviteAccepted
        )
        .map { (b0, b1) in !(b0 || b1) }
        .receive(on: RunLoop.main)
        .assign(to: \.isEditable, on: self.editableViewState)
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
                    inviteMessage: translator.t("persistentInvitations.is_inviting_to_join_org")
                        .replacingOccurrences(of: "{organization}", with: inviteInfo.orgName)
                )

                Task { @MainActor in
                    inviteDisplay = inviterText
                }
            }
        }
    }

    private func clearErrors() {
        inviteFailMessageSubject.value = ""
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
                        acceptedTitle = translator.t("persistentInvitations.account_created")
                        isInviteAcceptedSubject.value = true
                    }
                    // TODO: Back to sign in with email?
                    //       Or retrieve and set tokens?
                } else {
                    var errorMessageTranslateKey = "persistentInvitations.join_org_error"
                    switch joinResult {
                    case .redundant:
                        errorMessageTranslateKey = "persistentInvitations.already_in_org_error"
                    default:
                        if inviteDisplay?.inviteInfo.expiration.isPast == true {
                            errorMessageTranslateKey = "persistentInvitations.invite_expired_try_again"
                        }
                    }
                    inviteFailMessageSubject.value = translator.t(errorMessageTranslateKey)
                }
            }
        }
    }
}
