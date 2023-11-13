import Combine
import SwiftUI

class InviteTeammateViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let inputValidator: InputValidator
    private let qrCodeGenerator: QrCodeGenerator
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let isValidatingAccount = CurrentValueSubject<Bool, Never>(true)

    @Published private(set) var isLoading = false

    @Published private(set) var hasValidTokens = false

    @Published private(set) var myOrgInviteOptionText = ""
    @Published private(set) var anotherOrgInviteOptionText = ""
    @Published private(set) var scanQrCodeText = ""

    @Published var inviteToAnotherOrg = false
    @Published private(set) var accountData = emptyAccountData
    @Published private var affiliateOrganizationIds: Set<Int64>?
    @Published private(set) var selectedOtherOrg = OrganizationIdName(id: 0, name: "")
    @Published var organizationNameQuery = ""
    private let isSearchingLocalOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    private let isSearchingNetworkOrganizationsSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSearchingOrganizations = false
    @Published private(set) var organizationsSearchResult = [OrganizationIdName]()
    /// New or existing non-affiliate
    @Published private(set) var inviteOrgState = InviteOrgState(own: false, affiliate: false, nonAffiliate: false, new: false)

    @Published var inviteEmailAddresses = ""
    @Published var invitePhoneNumber = ""

    private let inviteUrl: String
    private let isCreatingMyOrgPersistentInvitation = CurrentValueSubject<Bool, Never>(false)
    @Published private var joinMyOrgInvite: JoinOrgInvite?
    private let isGeneratingMyOrgQrCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isGeneratingQrCode = false
    @Published private(set) var myOrgInviteQrCode: UIImage?

    private let affiliateInviteLatestPublisher = LatestAsyncThrowsPublisher<OrgQrCode>()
    private let generatingAffiliateOrgQrCodeSubject = CurrentValueSubject<Int64, Never>(0)
    @Published private(set) var isGeneratingAffiliateQrCode = false
    @Published private var affiliateOrgInviteQrCode = OrgQrCode(orgId: 0, qrCode: nil)
    @Published private(set) var affiliateOrgQrCode: UIImage?

    private let isSendingInviteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSendingInvite = false
    @Published private(set) var isInviteSent = false
    @Published private(set) var inviteSentTitle = ""
    @Published private(set) var inviteSentText = ""

    private let emailAddressErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var emailAddressErrorMessage = ""

    private let sendInviteErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var sendInviteErrorMessage = ""

    let editableView = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        orgVolunteerRepository: OrgVolunteerRepository,
        settingsProvider: AppSettingsProvider,
        inputValidator: InputValidator,
        qrCodeGenerator: QrCodeGenerator,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.orgVolunteerRepository = orgVolunteerRepository
        self.inputValidator = inputValidator
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

        Publishers.CombineLatest(
            isValidatingAccount,
            $affiliateOrganizationIds
        )
        .map { (b0, affiliateIds) in b0 || affiliateIds == nil }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &subscriptions)

        emailAddressErrorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.emailAddressErrorMessage, on: self)
            .store(in: &subscriptions)

        $isSendingInvite
            .sink { b0 in
                self.editableView.isEditable = !b0
            }
            .store(in: &subscriptions)

        sendInviteErrorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.sendInviteErrorMessage, on: self)
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

        $accountData.asyncMap { accountData in
            let orgId = accountData.org.id
            // TODO: Handle sync fail accordingly
            await self.organizationsRepository.syncOrganization(orgId, force: true, updateLocations: false)
            var affiliateIds = self.organizationsRepository.getOrganizationAffiliateIds(orgId, addOrganizationId: false)
            return affiliateIds
        }
        .receive(on: RunLoop.main)
        .assign(to: \.affiliateOrganizationIds, on: self)
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

        let otherOrgQuery = Publishers.CombineLatest(
            $inviteToAnotherOrg,
            $organizationNameQuery
        )
            .map { (inviteToAnother, q) in
                inviteToAnother ? q : ""
            }
        Publishers.CombineLatest4(
            $inviteToAnotherOrg,
            $selectedOtherOrg,
            otherOrgQuery,
            $affiliateOrganizationIds
        )
        .filter { (_, _, _, affiliates) in affiliates != nil }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { _ in
        }, receiveValue: { (inviteToAnother, selected, q, affiliates) in
            var isNew = false
            var isAffiliate = false
            var isNonAffiliate = false

            if inviteToAnother,
               q.isNotBlank {
                if selected.id > 0,
                   q.trim() == selected.name.trim() {
                    if affiliates!.contains(selected.id) {
                        isAffiliate = true
                    } else {
                        isNonAffiliate = true
                    }
                }

                isNew = !(isAffiliate || isNonAffiliate)
            }

            self.inviteOrgState = InviteOrgState(
                own: !inviteToAnother,
                affiliate: isAffiliate,
                nonAffiliate: isNonAffiliate,
                new: isNew
            )
        })
        .store(in: &subscriptions)

        $organizationNameQuery
            .receive(on: RunLoop.main)
            .sink { q in
                if q.isNotBlank {
                    self.sendInviteErrorMessageSubject.value = ""
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

    private func makeInviteUrl(_ userId: Int64, _ invite: JoinOrgInvite) -> String {
        "\(self.inviteUrl)?org-id=\(invite.orgId)&user-id=\(userId)&invite-token=\(invite.token)"
    }

    private func subscribeInviteQrCode() {
        let isGeneratingAffiliateInvite = Publishers.CombineLatest(
            generatingAffiliateOrgQrCodeSubject,
            $selectedOtherOrg
        )
            .map { (generatingOrgId, selectedOrg) in
                generatingOrgId > 0 && generatingOrgId == selectedOrg.id
            }

        isGeneratingAffiliateInvite
            .receive(on: RunLoop.main)
            .assign(to: \.isGeneratingAffiliateQrCode, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            isCreatingMyOrgPersistentInvitation,
            isGeneratingMyOrgQrCodeSubject,
            isGeneratingAffiliateInvite
        )
        .map { (b0, b1, b2) in b0 || b1 || b2 }
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
                    let invite = await self.orgVolunteerRepository.getOrganizationInvite(organizationId: orgId, inviterUserId: userId)
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
                    let inviteUrl = self.makeInviteUrl(account.id, invite)
                    return self.qrCodeGenerator.generate(inviteUrl)
                }
            }
            return nil
        }
        .receive(on: RunLoop.main)
        .assign(to: \.myOrgInviteQrCode, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest3(
            $accountData,
            $selectedOtherOrg,
            $affiliateOrganizationIds
        ).filter { (accountData, otherOrg, affiliates) in
            accountData.hasAuthenticated &&
            otherOrg.id > 0 &&
            affiliates?.contains(otherOrg.id) == true
        }
        .map { (account, otherOrgIdName, _) in
            self.affiliateInviteLatestPublisher.publisher {
                self.generatingAffiliateOrgQrCodeSubject.value = otherOrgIdName.id
                do {
                    defer {
                        // TODO: Atomic update
                        if self.generatingAffiliateOrgQrCodeSubject.value == otherOrgIdName.id {
                            self.generatingAffiliateOrgQrCodeSubject.value = 0
                        }
                    }

                    let orgId = otherOrgIdName.id
                    let userId = account.id
                    let invite = await self.orgVolunteerRepository.getOrganizationInvite(organizationId: orgId, inviterUserId: userId)

                    try Task.checkCancellation()

                    let inviteUrl = self.makeInviteUrl(account.id, invite)
                    let qrCode = self.qrCodeGenerator.generate(inviteUrl)

                    try Task.checkCancellation()

                    return OrgQrCode(orgId: orgId, qrCode: qrCode)
                }
            }
        }
        .switchToLatest()
        .receive(on: RunLoop.main)
        .assign(to: \.affiliateOrgInviteQrCode, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest4(
            $inviteToAnotherOrg,
            $inviteOrgState,
            $selectedOtherOrg,
            $affiliateOrgInviteQrCode
        )
        .map { (inviteToAnother, inviteOrg, selectedOther, invite) in
            return inviteToAnother &&
            inviteOrg.ownOrAffiliate &&
            invite.orgId > 0 &&
            selectedOther.id == invite.orgId ? invite.qrCode : nil
        }
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .assign(to: \.affiliateOrgQrCode, on: self)
        .store(in: &subscriptions)
    }

    func onSelectOrganization(_ organization: OrganizationIdName) {
        selectedOtherOrg = organization
        organizationNameQuery = organization.name
    }

    private func validateSendEmailAddresses() -> [String] {
        var errorMessage = ""
        let emailAddresses = inviteEmailAddresses.split(separator: ",")
            .map { s in String(s).trim() }
            .filter { s in s.isNotBlank }
        if emailAddresses.isEmpty {
            errorMessage = translator.t("~~Enter email addresses to invite.")
        } else {
            let invalidEmailAddresses = emailAddresses.map { s in
                inputValidator.validateEmailAddress(s)
                ? ""
                : translator.t("~~{email} is not a valid email address")
                    .replacingOccurrences(of: "{email}", with: s)
            }
            errorMessage = invalidEmailAddresses.filter { s in s.isNotBlank }
                .joined(separator: "\n")
        }

        if errorMessage.isNotBlank {
            emailAddressErrorMessageSubject.value = errorMessage
            return []
        }

        return emailAddresses
    }

    func onOrgQueryClose() {
        var matchingOrg = OrganizationIdName(id: 0, name: "")
        let orgQueryLower = organizationNameQuery.trim().lowercased()
        for result in organizationsSearchResult {
            if result.name.trim().lowercased() == orgQueryLower {
                matchingOrg = result
                break
            }
        }
        if selectedOtherOrg.id != matchingOrg.id {
            selectedOtherOrg = matchingOrg
            organizationNameQuery = matchingOrg.name
        }
    }

    private func inviteToOrgOrAffiliate(_ emailAddresses: [String], _ organizationId: Int64? = nil) async -> Bool {
        var notInvited = [String]()
        for emailAddress in emailAddresses {
            let invited = await orgVolunteerRepository.inviteToOrganization(emailAddress, organizationId: organizationId)
            if !invited {
                notInvited.append(emailAddress)
            }
        }

        if notInvited.isNotEmpty {
            sendInviteErrorMessage = translator.t("~~There were issues during invite. The following were not invited: {email_addresses}.")
                .replacingOccurrences(of: "{email_addresses}", with: notInvited.joined(separator: "\n  "))
            return false
        }
        return true
    }

    @MainActor
    private func onInviteSentToOrgOrAffiliate(_ emailAddresses: [String]) {
        inviteSentTitle = translator.t("~~Great. These users have received invites")
        inviteSentText = translator.t(emailAddresses.joined(separator: "\n"))
        isInviteSent = true
    }

    func sendInvites() {
        emailAddressErrorMessageSubject.value = ""
        sendInviteErrorMessageSubject.value = ""

        let myEmailAddressLower = accountData.emailAddress.trim().lowercased()
        let emailAddresses = validateSendEmailAddresses()
            .filter { s in s.lowercased() != myEmailAddressLower }
        guard emailAddresses.isNotEmpty else {
            return
        }

        if inviteOrgState.new,
           emailAddresses.count > 1 {
            emailAddressErrorMessageSubject.value = translator.t("~~Only one email is allowed when registering a new organization")
            return
        }

        if inviteToAnotherOrg {
            if selectedOtherOrg.id > 0 {
                if selectedOtherOrg.name != organizationNameQuery {
                    sendInviteErrorMessageSubject.value = translator.t("~~Search and select an organization to invite to. Select one of the organization options.")
                    return
                }
            } else {
                if organizationNameQuery.trim().isBlank {
                    sendInviteErrorMessageSubject.value = translator.t("~~Enter or search and select an organization to invite to.")
                    return
                }
            }
        }

        guard !isSendingInviteSubject.value else {
            return
        }
        isSendingInviteSubject.value = true
        Task {
            do {
                defer {
                    isSendingInviteSubject.value = false
                }

                var isSentToOrgOrAffiliate = false
                if inviteToAnotherOrg {
                    if inviteOrgState.new {
                        // TODO: Finish

                    } else if inviteOrgState.affiliate {
                        isSentToOrgOrAffiliate = await inviteToOrgOrAffiliate(emailAddresses, selectedOtherOrg.id)

                    } else if inviteOrgState.nonAffiliate {
                        // TODO: Finish

                    }
                } else {
                    isSentToOrgOrAffiliate = await inviteToOrgOrAffiliate(emailAddresses)
                }

                if isSentToOrgOrAffiliate {
                    await onInviteSentToOrgOrAffiliate(emailAddresses)
                }

            } catch {
                logger.logError(error)
                // TODO: Error message
            }
        }
    }
}

internal struct OrgSearch {
    let q: String
    let organizations: Array<OrganizationIdName>
}

fileprivate struct OrgQrCode {
    let orgId: Int64
    let qrCode: UIImage?
}

internal struct InviteOrgState {
    let own: Bool
    let affiliate: Bool
    let nonAffiliate: Bool
    let new: Bool

    var ownOrAffiliate: Bool { own || affiliate }
}
