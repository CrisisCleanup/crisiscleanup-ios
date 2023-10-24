import Combine
import SwiftUI

class InviteTeammateViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let qrCodeGenerator: QrCodeGenerator
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let isValidatingAccount = CurrentValueSubject<Bool, Never>(true)

    @Published var isLoading = false

    @Published var hasValidTokens = false

    @Published private(set) var myOrgInviteOptionText = ""
    @Published private(set) var anotherOrgInviteOptionText = ""

    @Published var inviteToAnotherOrg = false
    private var myOrg = OrgData(id: 0, name: "")
    @Published private(set) var selectedOtherOrg = OrganizationIdName(id: 0, name: "")
    @Published var organizationNameQuery = ""
    private let isSearchingLocalOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSearchingNetworkOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSearchingOrganizations = false
    @Published var organizationsSearchResult = [OrganizationIdName]()

    @Published var inviteEmailAddresses = ""

    private let inviteUrl: String
    private let isGeneratingQrCodeSubject = CurrentValueSubject<Bool, Never>(true)
    @Published private(set) var isGeneratingQrCode = false
    @Published private(set) var inviteQrCode: UIImage?

    private let isSendingInviteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSendingInvite = false
    @Published private(set) var isInviteSent = false

    let editableView = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        settingsProvider: AppSettingsProvider,
        qrCodeGenerator: QrCodeGenerator,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.qrCodeGenerator = qrCodeGenerator
        self.translator = translator
        logger = loggerFactory.getLogger("invite-teammate")
        inviteUrl = "\(settingsProvider.baseUrl)/mobile_app_user_invite"
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeAccountData()
        subscribeOrganizationState()
        subscribeSendState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        isValidatingAccount
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        $isSendingInvite
            .sink { b0 in
                self.editableView.isEditable = !b0
            }
            .store(in: &subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { accountData in
                self.myOrg = accountData.org
                self.myOrgInviteOptionText = self.translator.t("~~Part of {my_organization}")
                    .replacingOccurrences(of: "{my_organization}", with: accountData.org.name)
                self.hasValidTokens = accountData.areTokensValid
                self.isValidatingAccount.value = false
            }
            .store(in: &subscriptions)
    }

    private func subscribeOrganizationState() {
        anotherOrgInviteOptionText = translator.t("~~From another organization")

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
        isGeneratingQrCodeSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isGeneratingQrCode, on: self)
            .store(in: &subscriptions)

//        accountDataRepository.accountData.eraseToAnyPublisher()
//            .filter { $0.hasAuthenticated }
//            .map { data in
//                do {
//                    defer {
//                        self.isGeneratingQrCodeSubject.value = false
//                    }
//
//                    let userId = data.id
//                    let inviteUrl = "\(self.inviteUrl)?user-id=\(userId)"
//                    return self.qrCodeGenerator.generate(inviteUrl)
//                }
//            }
//            .receive(on: RunLoop.main)
//            .assign(to: \.inviteQrCode, on: self)
//            .store(in: &subscriptions)
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
