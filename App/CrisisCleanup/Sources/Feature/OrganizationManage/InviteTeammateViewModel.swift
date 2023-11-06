import Combine
import SwiftUI

class InviteTeammateViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let qrCodeGenerator: QrCodeGenerator
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let isValidatingAccount = CurrentValueSubject<Bool, Never>(true)

    @Published var isLoading = false

    @Published var hasValidTokens = false

    @Published private(set) var myOrgInviteOptionText = ""
    @Published private(set) var anotherOrgInviteOptionText = ""
    @Published private(set) var scanQrCodeText = ""

    @Published var inviteToAnotherOrg = false
    @Published private(set) var accountData = emptyAccountData
    @Published private(set) var selectedOtherOrg = OrganizationIdName(id: 0, name: "")
    @Published var organizationNameQuery = ""
    private let isSearchingLocalOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSearchingNetworkOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSearchingOrganizations = false
    @Published var organizationsSearchResult = [OrganizationIdName]()

    @Published var inviteEmailAddresses = ""

    private let inviteUrl: String
    private let isCreatingMyOrgPersistentInvitation = CurrentValueSubject<Bool, Never>(false)
    @Published private var joinMyOrgInvite: JoinOrgInvite?
    private let isGeneratingMyOrgQrCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isGeneratingQrCode = false
    @Published private(set) var myOrgInviteQrCode: UIImage?

    private let isSendingInviteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSendingInvite = false
    @Published private(set) var isInviteSent = false

    let editableView = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        orgVolunteerRepository: OrgVolunteerRepository,
        settingsProvider: AppSettingsProvider,
        qrCodeGenerator: QrCodeGenerator,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.qrCodeGenerator = qrCodeGenerator
        self.translator = translator
        logger = loggerFactory.getLogger("invite-teammate")
        inviteUrl = "\(settingsProvider.baseUrl)/mobile_app_user_invite"
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeAccountData()
        subscribeOrganizationState()
        subscribeInviteQrCode()
        subscribeSendState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        anotherOrgInviteOptionText = translator.t("~~From another organization")

        isValidatingAccount
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        $isSendingInvite
            .sink { b0 in
                self.editableView.isEditable = !b0
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $accountData,
            $inviteToAnotherOrg
        )
        .filter({ (account, _) in account.id > 0 })
        .map { (account, inviteToOther) in
            inviteToOther
            ? self.translator.t("~~Invite via QR code")
            : self.translator.t("~~Scan QR code to invite to {organization}")
                .replacingOccurrences(of: "{organization}", with: account.org.name)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.scanQrCodeText, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { accountData in
                self.accountData = accountData
                self.myOrgInviteOptionText = self.translator.t("~~Part of {my_organization}")
                    .replacingOccurrences(of: "{my_organization}", with: accountData.org.name)
                self.hasValidTokens = accountData.areTokensValid
                self.isValidatingAccount.value = false
            }
            .store(in: &subscriptions)
    }

    private func subscribeOrganizationState() {
        Publishers.CombineLatest(
            isSearchingLocalOrganizationsSubject,
            isSearchingNetworkOrganizationsSubject
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isSearchingOrganizations, on: self)
        .store(in: &subscriptions)

        // TODO: Indicate loading when querying local matches
        let qPublisher = $organizationNameQuery
            .debounce(
                for: .seconds(0.3),
                scheduler: RunLoop.current
            )
            .map { q in q.trim() }
        qPublisher
            .map { q in
                q.isEmpty
                ? Just([]).eraseToAnyPublisher()
                : self.organizationsRepository.streamMatchingOrganizations(q).eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.organizationsSearchResult, on: self)
            .store(in: &subscriptions)

        qPublisher
            .filter { $0.count > 1 }
            .sink(receiveValue: { q in
                self.isSearchingNetworkOrganizationsSubject.value = true
                do {
                    defer {
                        self.isSearchingNetworkOrganizationsSubject.value = false
                    }
                    await self.organizationsRepository.searchOrganizations(q)
                }
            })
            .store(in: &subscriptions)

        $inviteToAnotherOrg
            .sink { isAnotherOrg in
                if !isAnotherOrg {
                    self.selectedOtherOrg = OrganizationIdName(id: 0, name: "")
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeSendState() {
        isSendingInviteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSendingInvite, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeInviteQrCode() {
        Publishers.CombineLatest(
            isCreatingMyOrgPersistentInvitation,
            isGeneratingMyOrgQrCodeSubject
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isGeneratingQrCode, on: self)
        .store(in: &subscriptions)

        // TODO: Trigger refresh if cached invite is expired
        accountDataRepository.accountData.eraseToAnyPublisher()
            .filter { $0.hasAuthenticated }
            .asyncMap { data in
                self.isCreatingMyOrgPersistentInvitation.value = true
                do {
                    defer {
                        self.isCreatingMyOrgPersistentInvitation.value = false
                    }

                    let orgId = data.org.id

                    if let invite = self.joinMyOrgInvite,
                       invite.orgId == orgId,
                       !invite.isExpired
                    {
                        return self.joinMyOrgInvite
                    }

                    let userId = data.id
                    let invite = await self.orgVolunteerRepository.getOrgInvite(orgId: orgId, inviterUserId: userId)
                    return invite
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.joinMyOrgInvite, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $accountData,
            $joinMyOrgInvite
        )
        .filter { (account, invite) in
            account.hasAuthenticated && invite?.isExpired == false
        }
        .map { (account, invite) in
            self.isGeneratingMyOrgQrCodeSubject.value = true
            do {
                defer { self.isGeneratingMyOrgQrCodeSubject.value = false }

                if let invite = invite,
                   !invite.isExpired {
                    let inviteUrl = "\(self.inviteUrl)?org-id=\(invite.orgId)&user-id=\(account.id)&invite-token=\(invite.token)"
                    return self.qrCodeGenerator.generate(inviteUrl)
                }
            }
            return nil
        }
        .receive(on: RunLoop.main)
        .assign(to: \.myOrgInviteQrCode, on: self)
        .store(in: &subscriptions)
    }

    func onSelectOrganization(_ organization: OrganizationIdName) {
        selectedOtherOrg = organization
        organizationNameQuery = organization.name
    }

    func sendInvites() {
        // TODO: Validate

        isSendingInviteSubject.value = true
        // TODO: Finish
    }
}

internal struct OrgSearch {
    let q: String
    let organizations: Array<OrganizationIdName>
}
