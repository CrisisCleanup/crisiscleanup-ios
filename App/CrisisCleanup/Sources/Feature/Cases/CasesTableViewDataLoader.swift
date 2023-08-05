import Atomics
import Combine
import Foundation

class CasesTableViewDataLoader {
    private var worksiteProvider: WorksiteProvider
    private let worksitesRepository: WorksitesRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let organizationsRepository: OrganizationsRepository
    private let incidentsRepository: IncidentsRepository
    private let translator: KeyTranslator
    private let logger: AppLogger

    private let accountDataPublisher: AnyPublisher<AccountData, Never>

    private let isLoadingFlagsWorksite = CurrentValueSubject<Bool, Never>(false)
    private let isLoadingWorkTypeWorksite = CurrentValueSubject<Bool, Never>(false)
    let isLoading: any Publisher<Bool, Never>

    private let changingIdsLock = NSLock()
    private let worksiteChangingClaimIds = ManagedAtomic(AtomicSetInt64())
    let worksitesChangingClaimAction = CurrentValueSubject<Set<Int64>, Never>([])

    private var incidentWorkTypeLookup: (Int64, [String: String]) = (0, [:])

    init(
        worksiteProvider: WorksiteProvider,
        worksitesRepository: WorksitesRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        incidentsRepository: IncidentsRepository,
        translator: KeyTranslator,
        logger: AppLogger
    ) {
        self.worksiteProvider = worksiteProvider
        self.worksitesRepository = worksitesRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.organizationsRepository = organizationsRepository
        self.incidentsRepository = incidentsRepository
        self.translator = translator
        self.logger = logger

        accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()

        isLoading = Publishers.CombineLatest(
            isLoadingFlagsWorksite,
            isLoadingWorkTypeWorksite
        )
            .map { b0, b1 in b0 || b1 }
    }

    func loadWorksiteForAddFlags(_ worksite: Worksite) async -> Bool {
        isLoadingFlagsWorksite.value = true
        do {
            defer { isLoadingFlagsWorksite.value = false }

            var flagsWorksite = worksite
            let worksiteId = worksite.id
            if (worksiteId > 0 && worksite.networkId > 0) {
                let isSynced = await worksiteChangeRepository.trySyncWorksite(worksiteId)
                if isSynced {
                    if let cached = try await worksitesRepository.getWorksite(worksiteId) {
                        flagsWorksite = cached
                    }
                }
            }

            worksiteProvider.editableWorksite.value = flagsWorksite

            return true
        } catch {
            logger.logError(error)
        }
        return false
    }

    func onWorkTypeClaimAction(
        _ worksite: Worksite,
        _ claimAction: TableWorksiteClaimAction,
        _ transferWorkTypeProvider: TransferWorkTypeProvider
    ) async -> WorksiteClaimActionResult {
        let worksiteId = worksite.id

        let isInProgress = changingIdsLock.withLock {
            var changingIds = worksiteChangingClaimIds.load(ordering: .sequentiallyConsistent).value
            if (changingIds.contains(worksiteId)) {
                return true
            }
            changingIds.insert(worksiteId)
            worksitesChangingClaimAction.value = changingIds
            return false
        }
        guard !isInProgress else {
            return WorksiteClaimActionResult(isActionInProgress: true)
        }

        do {
            defer {
                changingIdsLock.withLock {
                    var changingIds = worksiteChangingClaimIds.load(ordering: .sequentiallyConsistent).value
                    changingIds.remove(worksiteId)
                    worksitesChangingClaimAction.value = changingIds
                }
            }

            var claimStatusWorksite = worksite
            let networkId = worksite.networkId
            if worksiteId > 0 && networkId > 0 {
                let isSynced = await worksiteChangeRepository.trySyncWorksite(worksiteId)
                if isSynced {
                    try await worksitesRepository.pullWorkTypeRequests(networkId)
                    if let cached = try await worksitesRepository.getWorksite(worksiteId) {
                        claimStatusWorksite = cached
                    }
                }
            }

            return try await completeTransfer(claimStatusWorksite, transferWorkTypeProvider, claimAction)
        } catch {
            logger.logError(error)
            return WorksiteClaimActionResult(
                errorMessage: "~~Something went wrong while making changes to {case_number}."
                    .replacingOccurrences(of: "{case_number}", with: worksite.caseNumber)
            )
        }
    }

    private func completeTransfer(
        _ worksite: Worksite,
        _ transferWorkTypeProvider: TransferWorkTypeProvider,
        _ claimAction: TableWorksiteClaimAction
    ) async throws -> WorksiteClaimActionResult {
        let incidentId = worksite.incidentId

        let myOrg = try await accountDataPublisher.asyncFirst().org
        let myOrgId = myOrg.id
        let affiliateIds = organizationsRepository.getOrganizationAffiliateIds(myOrgId)

        let claimStatus = worksite.getClaimStatus(affiliateIds)

        func startTransfer(_ transferType: WorkTypeTransferType) {
            let requested = worksite.workTypeRequests.filter { $0.hasNoResponse }
                .map { $0.workType }
            let claimedWorkTypes = worksite.workTypes.filter {
                if let orgClaim = $0.orgClaim {
                    return !affiliateIds.contains(orgClaim) &&
                    !requested.contains($0.workTypeLiteral)
                }
                return false
            }
            worksiteProvider.editableWorksite.value = worksite
            transferWorkTypeProvider.startTransfer(
                organizationId: myOrgId,
                transferType: transferType,
                workTypes: claimedWorkTypes.associate { ($0, false) },
                organizationName: myOrg.name,
                caseNumber: worksite.caseNumber
            )
        }

        switch claimAction {
        case .claim:
            if (claimStatus == .hasUnclaimed) {
                let changeWorkTypes = worksite.workTypes.map {
                    $0.isClaimed ? $0 : $0.copy { $0.orgClaim = myOrgId }
                }
                try await saveChanges(worksite, changeWorkTypes, myOrgId)
                return WorksiteClaimActionResult(isSuccess: true)
            }

        case .unclaim:
            if claimStatus == .claimedByMyOrg {
                let changeWorkTypes = worksite.workTypes.map {
                    $0.orgClaim != myOrgId ? $0 : $0.copy { $0.orgClaim = nil }
                }
                try await saveChanges(worksite, changeWorkTypes, myOrgId)
                return WorksiteClaimActionResult(isSuccess: true)
            }

        case .request:
            if claimStatus == .claimedByOthers {
                try await setWorkTypeLookup(incidentId)
                startTransfer(.request)
                return WorksiteClaimActionResult(isSuccess: true)
            }

        case .release:
            if claimStatus == .claimedByOthers {
                try await setWorkTypeLookup(incidentId)
                startTransfer(.release)
                return WorksiteClaimActionResult(isSuccess: true)
            }
        }

        return WorksiteClaimActionResult(statusChangedTo: claimStatus)
    }

    private func setWorkTypeLookup(_ incidentId: Int64) async throws {
        if incidentId != incidentWorkTypeLookup.0 {
            if let formFieldsIncident = try incidentsRepository.getIncident(incidentId, true) {
                let formFields = FormFieldNode.buildTree(
                    formFieldsIncident.formFields,
                    translator
                )
                    .map { $0.flatten() }

                let formFieldTranslationLookup = formFieldsIncident.formFields
                    .filter { $0.fieldKey.isNotBlank && $0.label.isNotBlank }
                    .associate { ($0.fieldKey, $0.label) }

                var workTypeFormFields = [FormFieldNode]()
                if let node = formFields.first(where: { $0.fieldKey == WorkFormGroupKey }) {
                    workTypeFormFields = node.children.filter { $0.parentKey == WorkFormGroupKey }
                }

                let workTypeTranslationLookup = workTypeFormFields.associate {
                    let name = formFieldTranslationLookup[$0.fieldKey] ?? $0.fieldKey
                    return ($0.formField.selectToggleWorkType, name)
                }

                incidentWorkTypeLookup = (incidentId, workTypeTranslationLookup)
            }
        }
        worksiteProvider.workTypeTranslationLookup = incidentWorkTypeLookup.1
    }

    private func saveChanges(
        _ worksite: Worksite,
        _ changedWorkTypes: [WorkType],
        _ organizationId: Int64
    ) async throws {
        if (worksite.workTypes == changedWorkTypes) {
            return
        }

        let changedWorksite = worksite.copy { $0.workTypes = changedWorkTypes }
        let primaryWorkType = worksite.keyWorkType ?? worksite.workTypes.first!
        _ = try await worksiteChangeRepository.saveWorksiteChange(
            worksiteStart: worksite,
            worksiteChange: changedWorksite,
            primaryWorkType: primaryWorkType,
            organizationId: organizationId
        )
    }
}

struct WorksiteClaimActionResult {
    let isSuccess: Bool
    let isActionInProgress: Bool
    let statusChangedTo: TableWorksiteClaimStatus?
    let errorMessage: String

    init(
        isSuccess: Bool = false,
        isActionInProgress: Bool = false,
        statusChangedTo: TableWorksiteClaimStatus? = nil,
        errorMessage: String = ""
    ) {
        self.isSuccess = isSuccess
        self.isActionInProgress = isActionInProgress
        self.statusChangedTo = statusChangedTo
        self.errorMessage = errorMessage
    }
}

private class AtomicSetInt64: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicSetInt64>

    let value: Set<Int64>

    init(_ value: Set<Int64> = []) {
        self.value = value
    }
}
