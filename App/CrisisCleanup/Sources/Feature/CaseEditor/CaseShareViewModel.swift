import Atomics
import Combine
import Foundation
import SwiftUI

class CaseShareViewModel: ObservableObject {
    private let editableWorksiteProvider: EditableWorksiteProvider
    private let usersRepository: UsersRepository
    private let organizationsRepository: OrganizationsRepository
    private let accountDataRepository: AccountDataRepository
    private let worksitesRepository: WorksitesRepository
    private let networkMonitor: NetworkMonitor
    private let inputValidator: InputValidator
    private let translator: KeyTranslator

    private let worksiteIn: Worksite

    private let isSharingSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSharing = false
    private let isSharedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isShared = false

    @Published var unclaimedShareReason = ""
    @Published var isEmailContactMethod = true
    @Published private(set) var contactErrorMessage = ""
    @Published private(set) var receiverContacts = [ShareContactInfo]()
    @Published var receiverContactManual = ""
    @Published var receiverContactSuggestion = ""

    private let organizationId: AnyPublisher<Int64, Never>

    @Published private(set) var hasClaimedWorkType: Bool? = nil

    @Published private(set) var isLoading = true
    @Published private(set) var showShareScreen = false

    @Published private(set) var isSharable = true
    @Published private(set) var notSharableMessage = ""

    @Published private(set) var isShareEnabled = false

    @Published private(set) var contactOptions = [ShareContactInfo]()

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        editableWorksiteProvider: EditableWorksiteProvider,
        usersRepository: UsersRepository,
        organizationsRepository: OrganizationsRepository,
        accountDataRepository: AccountDataRepository,
        worksitesRepository: WorksitesRepository,
        networkMonitor: NetworkMonitor,
        inputValidator: InputValidator,
        translator: KeyTranslator
    ) {
        self.editableWorksiteProvider = editableWorksiteProvider
        self.usersRepository = usersRepository
        self.organizationsRepository = organizationsRepository
        self.accountDataRepository = accountDataRepository
        self.worksitesRepository = worksitesRepository
        self.networkMonitor = networkMonitor
        self.inputValidator = inputValidator
        self.translator = translator

        worksiteIn = editableWorksiteProvider.editableWorksite.value

        organizationId = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map { $0.org.id }
            .eraseToAnyPublisher()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .relaxed)
        if isFirstAppear {
            subscribeLoadingState()
            subscribeOrganization()
            subscribeQueryState()
            subscribeShareState()
        }
    }

    func onViewDisappear() {
        // Multi screen flow
    }

    deinit {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoadingState() {
         $hasClaimedWorkType
            .map { $0 == nil }
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeOrganization() {
        organizationId
            .map { orgId in
                let affiliatedOrgIds = self.organizationsRepository.getOrganizationAffiliateIds(orgId, addOrganizationId: true)
                let claimedBys = Set(self.worksiteIn.workTypes.compactMap { $0.orgClaim })
                let isClaimed = claimedBys.first(where: { claimedBy in
                    affiliatedOrgIds.contains(claimedBy)
                }) != nil
                return isClaimed
            }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { isClaimed in
                if isClaimed {
                    self.showShareScreen = true
                }

                self.hasClaimedWorkType = isClaimed
            })
            .store(in: &subscriptions)
    }

    private let latestContactOptionsPublisher = LatestAsyncPublisher<[ShareContactInfo]>()
    private func subscribeQueryState() {
        $receiverContactManual
            .receive(on: RunLoop.main)
            .sink(receiveValue: { s in
                if s.isBlank {
                    self.contactErrorMessage = ""
                }
            })
            .store(in: &subscriptions)

        let contactQuery = $receiverContactSuggestion
            .map { $0.trim() }
            .removeDuplicates()
            .eraseToAnyPublisher()

        Publishers.CombineLatest(
            organizationId,
            contactQuery
        )
        .map { orgId, query in self.latestContactOptionsPublisher.publisher {
            if query.count < 2 {
                return []
            }

            let isEmailContact = self.isEmailContactMethod
            // TODO: Overlay/show loading indicator when query is in progress
            let contacts = await self.usersRepository.getMatchingUsers(query, orgId).map {
                let contactValue = isEmailContact ? $0.email : $0.mobile
                return ShareContactInfo(
                    name: $0.fullName,
                    contactValue: contactValue.trim(),
                    isEmail: isEmailContact
                )
            }
            return contacts
        }}
        .switchToLatest()
        .receive(on: RunLoop.main)
        .assign(to: \.contactOptions, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeShareState() {
        isSharingSubject
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isSharing, on: self)
            .store(in: &subscriptions)

        isSharedSubject
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isShared, on: self)
            .store(in: &subscriptions)

        let isOnlinePublisher = networkMonitor.isOnline.eraseToAnyPublisher()
        let accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()

        Publishers.CombineLatest(
            isOnlinePublisher,
            accountDataPublisher
        )
        .map { (online, accountData) in
            online && accountData.areTokensValid
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isSharable, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest(
            isOnlinePublisher,
            accountDataPublisher
        )
        .map{ (online, accountData) in
            var message = ""
            if !online {
                message = self.translator.t("info.share_requires_internet")
            } else if !accountData.areTokensValid {
                message = self.translator.t("info.share_requires_login")
            }
            return message
        }
        .receive(on: RunLoop.main)
        .assign(to: \.notSharableMessage, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest4(
            $isSharable,
            $isLoading,
            $isSharing,
            $receiverContacts
        )
        .map { (sharable, loading, sharing, contacts) in
            sharable &&
            !loading &&
            !sharing &&
            contacts.isNotEmpty
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isShareEnabled, on: self)
        .store(in: &subscriptions)
    }

    private func addContact(_ contactInfo: ShareContactInfo) {
        let existingContacts = Set(receiverContacts.map { $0.contactValue })
        if !existingContacts.contains(contactInfo.contactValue) {
            receiverContacts.append(contactInfo)
        }
    }

    func onAddContact(_ contact: String) {
        contactErrorMessage = ""

        if contact.isNotBlank {
            let isEmail = isEmailContactMethod
            if isEmail {
                if (!inputValidator.validateEmailAddress(contact)) {
                    contactErrorMessage = translator.t("info.enter_valid_email")
                    return
                }
            } else {
                if (!inputValidator.validatePhoneNumber(contact)) {
                    contactErrorMessage = translator.t("info.enter_valid_phone")
                    return
                }
            }

            let contactInfo = ShareContactInfo(
                name: "",
                contactValue: contact.trim(),
                isEmail: isEmail
            )
            addContact(contactInfo)
            receiverContactManual = ""
        }
    }

    func onAddContact(_ contact: ShareContactInfo) {
        if contact.contactValue.isNotBlank {
            addContact(contact)
            receiverContactSuggestion = ""
        }
    }

    func deleteContact(_ index: Int) {
        if 0 <= index && index < receiverContacts.count {
            receiverContacts.remove(at: index)
        }
    }

    func onShare(_ shareMessage: String) {
        let noClaimReason = unclaimedShareReason
        let contacts = receiverContacts
        let emails = contacts.filter { $0.isEmail }
        let phoneNumbers = contacts.filter { !$0.isEmail }
        if emails.isEmpty && phoneNumbers.isEmpty {
            return
        }

        if isSharingSubject.value {
            return
        }
        isSharingSubject.value = true

        Task {
            do {
                defer { isSharingSubject.value = false }

                isSharedSubject.value = await worksitesRepository.shareWorksite(
                    worksiteId: worksiteIn.id,
                    emails: emails.map { $0.contactValue },
                    phoneNumbers: phoneNumbers.map { $0.contactValue },
                    shareMessage: shareMessage,
                    noClaimReason: noClaimReason
                )
            }
        }
    }
}

struct ShareContactInfo: Hashable {
    let name: String
    let contactValue: String
    let isEmail: Bool
}
