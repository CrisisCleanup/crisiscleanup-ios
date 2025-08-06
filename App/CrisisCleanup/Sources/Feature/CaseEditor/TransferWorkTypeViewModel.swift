import Atomics
import Combine
import Foundation
import SwiftUI

class TransferWorkTypeViewModel: ObservableObject, KeyAssetTranslator {
    private let organizationsRepository: OrganizationsRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let editableWorksiteProvider: EditableWorksiteProvider
    private let transferWorkTypeProvider: TransferWorkTypeProvider
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    var transferType: WorkTypeTransferType { transferWorkTypeProvider.transferType }

    var isTransferable: Bool { transferType != .none && transferWorkTypeProvider.workTypes.isNotEmpty
    }

    private var organizationId: Int64 { transferWorkTypeProvider.organizationId }

    var screenTitle: String {
        switch transferType {
        case .release: return t("actions.release")
        case .request: return t("workTypeRequestModal.work_type_request")
        default: return ""
        }
    }

    private let isTransferredSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isTransferred = false
    private let isTransferringSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isTransferring = false

    var transferWorkTypesState: [WorkType: Bool] { transferWorkTypeProvider.workTypes }
    lazy var workTypeList: [WorkType] = {
        transferWorkTypesState.keys.sorted { a, b in
            a.workTypeLiteral.localizedCompare(b.workTypeLiteral) == .orderedAscending
        }
    }()
    @Published var workTypesState = [Int64: Bool]()

    private var subscriptions = Set<AnyCancellable>()

    @Published var transferReason = ""

    var reasonHint: String {
        transferType == .request ? t("workTypeRequestModal.reason_requested") : ""
    }

    @Published private(set) var errorMessageReason = ""
    @Published private(set) var errorMessageWorkType = ""

    @Published private var requestWorkTypesState = RequestWorkTypeState()

    @Published private(set) var requestDescription = ""

    @Published private(set) var contactList = [OrgContactInfoDisplay]()

    private let isFirstVisible = ManagedAtomic(true)

    init(
        organizationsRepository: OrganizationsRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        editableWorksiteProvider: EditableWorksiteProvider,
        transferWorkTypeProvider: TransferWorkTypeProvider,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        syncPusher: SyncPusher,
        loggerFactory: AppLoggerFactory
    ) {
        self.organizationsRepository = organizationsRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.editableWorksiteProvider = editableWorksiteProvider
        self.transferWorkTypeProvider = transferWorkTypeProvider
        self.inputValidator = inputValidator
        self.translator = translator
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("transfer-work-type")

        translationCount = translator.translationCount
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .relaxed)
        if isFirstAppear {
            transferWorkTypesState.forEach { workTypesState[$0.key.id] = $0.value }
            transferWorkTypeProvider.clearPendingTransfer()
        }

        subscribeToTransferState()
        subscribeToWorkTypesState()
        subscribeToContactList()
        subscribeToRequestDescription()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToTransferState() {
        isTransferringSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isTransferring, on: self)
            .store(in: &subscriptions)

        isTransferredSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isTransferred, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToWorkTypesState() {
        organizationsRepository.organizationLookup
            .eraseToAnyPublisher()
            .map { orgLookup in
                let orgNameLookup = self.transferWorkTypesState
                    .compactMap { (workType, _) in
                        if let orgClaim = workType.orgClaim,
                           let org = orgLookup[orgClaim] {
                            return (workType.id, org.name)
                        }
                        return nil
                    }
                    .associate { $0 }
                let contactLookup = self.transferWorkTypesState
                    .compactMap { (workType, _) in
                        if let orgClaim = workType.orgClaim,
                           let org = orgLookup[orgClaim] {
                            let orgContacts = org.primaryContacts.map {
                                OrgContactInfoDisplay(
                                    contactName: $0.fullName,
                                    orgName: org.name,
                                    isValidEmail: self.inputValidator.validateEmailAddress($0.email),
                                    email: $0.email,
                                    isValidMobile: self.inputValidator.validatePhoneNumber($0.mobile).isValid,
                                    mobile: $0.mobile
                                )
                            }
                            return (org.id, orgContacts)
                        }
                        return nil
                    }
                    .associate { $0 }
                return RequestWorkTypeState(orgNameLookup, contactLookup)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.requestWorkTypesState, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToContactList() {
        $requestWorkTypesState
            .map { workTypeState in
                let contactListLookup = workTypeState.orgIdContactListLookup
                let contacts = Set(self.transferWorkTypesState.compactMap { $0.key.orgClaim })
                    .compactMap { contactListLookup[$0] }
                    .joined()
                return Array(contacts)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.contactList, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToRequestDescription() {
        if (transferType == .request) {
            Publishers.CombineLatest(
                $requestWorkTypesState,
                $workTypesState
            )
                .map { (requestState, workTypesState) in
                    let orgLookup = requestState.workTypeIdOrgNameLookup
                    let orgIds = workTypesState
                        .filter { $0.value }
                        .map { $0.key }
                        .compactMap { orgLookup[$0] }
                    let otherOrganizations = Set(orgIds).joined(separator: ", ")
                    let provider = self.transferWorkTypeProvider
                    return self.t("workTypeRequestModal.request_modal_instructions")
                        .replacingOccurrences(of: "{organizations}", with: otherOrganizations)
                        .replacingOccurrences(of: "{my_organization}", with: provider.organizationName)
                        .replacingOccurrences(of: "{case_number}", with: provider.caseNumber)

                }
                .receive(on: RunLoop.main)
                .assign(to: \.requestDescription, on: self)
                .store(in: &subscriptions)
        }
    }

    func commitTransfer() -> Bool {
        errorMessageReason = ""
        errorMessageWorkType = ""

        if transferReason.isBlank {
            let isRelease = transferType == .release
            let reasonTranslateKey =
            isRelease ? "workTypeRequestModal.explain_release_case_required"
            : "workTypeRequestModal.explain_request_case_required"
            errorMessageReason = t(reasonTranslateKey)
        }

        let isWorkTypeChecked = workTypesState.contains(where: { (key, value) in value })
        if !isWorkTypeChecked {
            errorMessageWorkType =
            t("workTypeRequestModal.transfer_work_type_is_required")
        }

        if errorMessageReason.isBlank &&
            errorMessageWorkType.isBlank
        {
            transferWorkTypes()
            return true
        }

        return false
    }

    private func transferWorkTypes() {
        isTransferringSubject.value = true
        Task {
            let isRequest = transferType == .request
            let workTypeIdLookup = transferWorkTypesState.keys
                .map { ($0.id, $0.workTypeLiteral) }
                .associate { $0 }
            let workTypes = workTypesState.compactMap {
                $0.value ? workTypeIdLookup[$0.key] : nil
            }
            let worksite = editableWorksiteProvider.editableWorksite.value
            do {
                defer {
                    self.isTransferringSubject.value = false
                }

                let isSaved = try await worksiteChangeRepository.saveWorkTypeTransfer(
                    worksite: worksite,
                    organizationId: organizationId,
                    requestReason: isRequest ? transferReason : "",
                    requests: isRequest ? workTypes : [],
                    releaseReason: isRequest ? "" : transferReason,
                    releases: isRequest ? [] : workTypes
                )

                if isSaved {
                    syncPusher.appPushWorksite(worksite.id)

                    self.isTransferredSubject.value = true
                }
            } catch {
                // TODO Show error
                logger.logError(error)
            }
        }
    }

    // MARK: KeyAssetTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String) -> String? {
        t(phraseKey)
    }

    func t(_ phraseKey: String) -> String {
        editableWorksiteProvider.translate(key: phraseKey) ?? translator.translate(phraseKey, phraseKey)
    }

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        t(phraseKey)
    }
}

struct RequestWorkTypeState {
    let workTypeIdOrgNameLookup: [Int64: String]
    let orgIdContactListLookup: [Int64: [OrgContactInfoDisplay]]

    init(
        _ workTypeIdOrgNameLookup: [Int64 : String] = [:],
        _ orgIdContactListLookup: [Int64 : [OrgContactInfoDisplay]] = [:]
    ) {
        self.workTypeIdOrgNameLookup = workTypeIdOrgNameLookup
        self.orgIdContactListLookup = orgIdContactListLookup
    }
}

struct OrgContactInfoDisplay: Hashable {
    let contactName: String
    let orgName: String
    let isValidEmail: Bool
    let email: String
    let isValidMobile: Bool
    let mobile: String

    var hasContactInfo: Bool { email.isNotBlank && mobile.isNotBlank }
}
