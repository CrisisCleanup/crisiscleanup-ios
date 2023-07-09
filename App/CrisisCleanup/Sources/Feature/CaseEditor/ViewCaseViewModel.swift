import Atomics
import Combine
import Foundation
import SwiftUI

class ViewCaseViewModel: ObservableObject, KeyTranslator {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private var editableWorksiteProvider: EditableWorksiteProvider
    private let translator: KeyAssetTranslator
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let isValidWorksiteIds: Bool
    let incidentIdIn: Int64
    let worksiteIdIn: Int64

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""
    @Published private(set) var subTitle = ""

    @Published private(set) var isLoading = true

    @Published private(set) var isSyncing = false

    private let isSavingWorksite = CurrentValueSubject<Bool, Never>(false)
    private let isSavingMedia = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaving = false

    @Published private(set) var syncingWorksiteImage = 0

    private let isOrganizationsRefreshed = ManagedAtomic(false)
    private let organizationLookup: AnyPublisher<[Int64: IncidentOrganization], Never>

    private let editableWorksite: AnyPublisher<Worksite, Never>

    private let uiState: AnyPublisher<CaseEditorUiState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    @Published private(set) var workTypeProfile: WorkTypeProfile? = nil

    @Published private(set) var tabTitles: [ViewCaseTabs: String] = [
        .info: "",
        .photos: "",
        .notes: ""
    ]
    @Published private(set) var statusOptions: [WorkTypeStatus] = []
    @Published private(set) var beforeAfterPhotos: [ImageCategory: [CaseImage]] = [:]

    private let previousNoteCount = ManagedAtomic(0)

    var addImageCategory = ImageCategory.before

    private let nextRecurDateFormat: DateFormatter

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        organizationsRepository: OrganizationsRepository,
        incidentRefresher: IncidentRefresher,
        incidentBoundsProvider: IncidentBoundsProvider,
        worksitesRepository: WorksitesRepository,
        languageRepository: LanguageTranslationsRepository,
        languageRefresher: LanguageRefresher,
        workTypeStatusRepository: WorkTypeStatusRepository,
        editableWorksiteProvider: EditableWorksiteProvider,
        translator: KeyAssetTranslator,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        networkMonitor: NetworkMonitor,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.editableWorksiteProvider = editableWorksiteProvider
        self.translator = translator
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("view-case")

        translationCount = translator.translationCount

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        isValidWorksiteIds = incidentId > 0 && worksiteId > 0

        localTranslate = { phraseKey in
            editableWorksiteProvider.translate(key: phraseKey) ?? translator(phraseKey)
        }

        dataLoader = CaseEditorDataLoader(
            isCreateWorksite: false,
            incidentIdIn: incidentIdIn,
            accountDataRepository: accountDataRepository,
            incidentsRepository: incidentsRepository,
            incidentRefresher: incidentRefresher,
            incidentBoundsProvider: incidentBoundsProvider,
            worksitesRepository: worksitesRepository,
            worksiteChangeRepository: worksiteChangeRepository,
            keyTranslator: languageRepository,
            languageRefresher: languageRefresher,
            workTypeStatusRepository: workTypeStatusRepository,
            editableWorksiteProvider: editableWorksiteProvider,
            networkMonitor: networkMonitor,
            appEnv: appEnv,
            loggerFactory: loggerFactory
        )
        uiState = dataLoader.uiState.eraseToAnyPublisher()

        organizationLookup = organizationsRepository.organizationLookup.eraseToAnyPublisher()

        editableWorksite = editableWorksiteProvider.editableWorksite.eraseToAnyPublisher()

        nextRecurDateFormat = DateFormatter()
        nextRecurDateFormat.dateFormat = "EEE MMMM d yyyy 'at' h:mm a"

        updateHeaderTitle()
        subscribeToSubTitle()
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            self.editableWorksiteProvider.reset(incidentIdIn)
        }

        subscribeToLoading()
        subscribeToSyncing()
        subscribeToSaving()

        subscribeToCaseData()
        subscribeToWorksiteChange()
        subscribeToWorkTypeProfile()
        subscribeToFilesNotes()

        if isFirstAppear {
            dataLoader.loadData(
                incidentIdIn: incidentIdIn,
                worksiteIdIn: worksiteIdIn,
                translate: localTranslate
            )
        }
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToLoading() {
        dataLoader.isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToSyncing() {
        // TODO: Combine with syncing images when available
        worksiteChangeRepository.syncingWorksiteIds
            .eraseToAnyPublisher()
            .map { syncingWorksiteIds in
                syncingWorksiteIds.contains(self.worksiteIdIn)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToSaving() {
        Publishers.CombineLatest(
            isSavingWorksite.eraseToAnyPublisher(),
            isSavingMedia.eraseToAnyPublisher()
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isSaving, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeToCaseData() {
        uiState
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { state in
                let result: CaseEditorCaseData? = {
                    switch state {
                    case .caseData(let caseData): return caseData
                    default: return nil
                    }
                }()
                return result
            }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { stateData in
                self.caseData = stateData
                self.statusOptions = stateData == nil ? [] : stateData!.statusOptions
            })
            .store(in: &subscriptions)
    }

    private func subscribeToWorksiteChange() {
        dataLoader.worksiteStream
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    self.worksitesRepository.setRecentWorksite(
                        incidentId: self.incidentIdIn,
                        worksiteId: localWorksite.worksite.id,
                        viewStart: Date()
                    )
                }
            })
            .store(in: &subscriptions)

        dataLoader.worksiteStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    self.updateHeaderTitle(localWorksite.worksite.caseNumber)
                }
            })
            .store(in: &subscriptions)
    }

    private func subscribeToWorkTypeProfile() {
        Publishers.CombineLatest3(
            $caseData.assertNoFailure().eraseToAnyPublisher(),
            editableWorksite,
            organizationLookup
        )
        .filter { (stateData, worksite, orgLookup) in
            stateData != nil &&
            !worksite.isNew &&
            orgLookup.isNotEmpty
        }
        .filter { (stateData, _, orgLookup) in
            orgLookup.keys.contains(stateData!.orgId)
        }
        .map { (stateData, worksite, orgLookup) in
            let stateData = stateData!
            let isTurnOnRelease = stateData.incident.turnOnRelease
            let myOrgId = stateData.orgId
            let worksiteWorkTypes = worksite.workTypes

            let myOrg = orgLookup[myOrgId]!

            let requestedTypes = Set(
                stateData.worksite.workTypeRequests
                    .filter { $0.hasNoResponse }
                    .map { $0.workType }
            )

            let summaries = self.getWorkTypeSummaries(
                worksiteWorkTypes,
                stateData,
                worksite,
                requestedTypes,
                isTurnOnRelease,
                myOrgId,
                myOrg
            )

            let claimedWorkType = summaries.filter { summary in summary.workType.orgClaim != nil }
            let unclaimed = summaries.filter { summary in summary.workType.orgClaim == nil }
            let otherOrgClaimedWorkTypes =
            claimedWorkType.filter { !$0.isClaimedByMyOrg }
            let orgClaimedWorkTypes = claimedWorkType.filter { $0.isClaimedByMyOrg }

            var otherOrgClaimMap = [Int64: [WorkTypeSummary]]()
            otherOrgClaimedWorkTypes.forEach { summary in
                let orgId = summary.workType.orgClaim!
                var otherOrgWorkTypes = otherOrgClaimMap[orgId] ?? []
                otherOrgWorkTypes.append(summary)
                otherOrgClaimMap[orgId] = otherOrgWorkTypes
            }
            let otherOrgClaims = otherOrgClaimMap.map { (orgId, summaries) in
                let name = orgLookup[orgId]?.name
                if name == nil {
                    self.refreshOrganizationLookup()
                }
                return OrgClaimWorkType(
                    orgId: orgId,
                    orgName: name ?? "",
                    workTypes: summaries,
                    isMyOrg: false
                )
            }

            let myOrgName = myOrg.name
            let orgClaimed = OrgClaimWorkType(
                orgId: myOrgId,
                orgName: myOrgName,
                workTypes: orgClaimedWorkTypes,
                isMyOrg: true
            )

            let releasable = otherOrgClaimedWorkTypes
                .filter { summary in summary.isReleasable }
                // TODO: Does this sort perform as expected
                .sorted(by: { a, b in a.name.localizedStandardCompare(b.name) == .orderedAscending })
            let requestable = otherOrgClaimedWorkTypes
                .filter { summary in !(summary.isReleasable || summary.isRequested) }
            // TODO: Does this sort perform as expected
                .sorted(by: { a, b in a.name.localizedStandardCompare(b.name) == .orderedAscending })
            return WorkTypeProfile(
                orgId: myOrgId,
                otherOrgClaims: otherOrgClaims,
                orgClaims: orgClaimed,
                unclaimed: unclaimed,
                releasable: releasable,
                requestable: requestable,

                orgName: myOrgName,
                caseNumber: worksite.caseNumber
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.workTypeProfile, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeToFilesNotes() {
        let filesNotes = Publishers.CombineLatest(
            editableWorksite,
            $caseData.eraseToAnyPublisher()
        )
            .filter { (_, state) in state != nil }
            .map { (worksite, state) in
                let state = state!
                let fileImages = worksite.files.map { $0.asCaseImage() }
                let localImages: [CaseImage]
                if let localWorksiteImages = state.localWorksite {
                    localImages = localWorksiteImages.localImages.map { $0.asCaseImage() }
                } else {
                    localImages = []
                }
                // TODO: Notes are not loading proper
                print("worksite \(worksite.notes)")
                return (fileImages, localImages, worksite.notes)
            }
            .share()

        filesNotes.map { (fileImages, localImages, notes) in
            let fileCount = fileImages.count + localImages.count
            var photosTitle = self.localTranslate("caseForm.photos")
            if fileCount > 0 {
                photosTitle = "\(photosTitle) (\(fileCount))"
            }

            var notesTitle = self.localTranslate("formLabels.notes")
            let noteCount = notes.count
            if noteCount > 0 {
                notesTitle = "\(notesTitle) (\(noteCount))"
            }

            return [
                .info: self.localTranslate("nav.info"),
                .photos: photosTitle,
                .notes: notesTitle
            ]
        }
        .receive(on: RunLoop.main)
        .assign(to: \.tabTitles, on: self)
        .store(in: &subscriptions)

        // TODO: Before and after photos when ready
    }

    private func getWorkTypeSummaries(
        _ worksiteWorkTypes: [WorkType],
        _ stateData: CaseEditorCaseData,
        _ worksite: Worksite,
        _ requestedTypes: Set<String>,
        _ isTurnOnRelease: Bool,
        _ myOrgId: Int64,
        _ myOrg: IncidentOrganization
    ) -> [WorkTypeSummary] {
        worksiteWorkTypes.map { workType in
            let workTypeLiteral = workType.workTypeLiteral
            var name = localTranslate(workTypeLiteral)
            if name == workTypeLiteral {
                name = localTranslate("workType.\(workTypeLiteral)")
            }
            let summaryJobTypes = worksite.summarizeWorkTypeJobs(
                stateData.incident.workTypeLookup,
                workTypeLiteral,
                localTranslate,
                name
            )
            let rRuleSummary: String? = {
//                if let rRuleString = workType.recur {
//                    // TODO: Use RRule library and customize where lacking
//                     return RRule(rRuleString).toHumanReadableText(translator)
//                }
                return nil
            }()
            let nextRecurSummary: String? = {
                if let nextRecurAt = workType.nextRecurAt,
                   nextRecurAt > Date.now {
                       let nextDate = nextRecurDateFormat.string(from: nextRecurAt)
                       return "\(localTranslate("shareWorksite.next_recur")) \(nextDate)"
                   }
                return nil
            }()
            let summary = [
                summaryJobTypes.combineTrimText(),
                rRuleSummary,
                nextRecurSummary,
            ]
                .combineTrimText("\n")
            return WorkTypeSummary(
                workType: workType,
                name: name,
                jobSummary: summary,
                isRequested: requestedTypes.contains(workType.workTypeLiteral),
                isReleasable: isTurnOnRelease && workType.isReleaseEligible,
                myOrgId: myOrgId,
                isClaimedByMyOrg: myOrg.affiliateIds.contains(workType.orgClaim ?? -1)
            )
        }
    }

    private func refreshOrganizationLookup() {
        if !isOrganizationsRefreshed.exchange(true, ordering: .sequentiallyConsistent) {
            Task {
                await incidentsRepository.pullIncidentOrganizations(incidentIdIn, true)
                await incidentsRepository.pullIncidentOrganizations(incidentIdIn, true)
            }
        }
    }

    private func updateHeaderTitle(_ caseNumber: String = "") {
        headerTitle = caseNumber.isEmpty
        ? localTranslate("nav.work_view_case")
        : "\(localTranslate("actions.view")) \(caseNumber)"
    }

    private func subscribeToSubTitle() {
        editableWorksite
            .map { worksite in
                worksite.isNew ? "" : [worksite.county, worksite.state]
                    .filter { $0.isNotBlank }
                    .joined(separator: ", ")
            }
            .receive(on: RunLoop.main)
            .assign(to: \.subTitle, on: self)
            .store(in: &subscriptions)
    }

    // MARK: KeyTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String) -> String? {
        localTranslate(phraseKey)
    }

    // TODO: Redesign for specific implementors. Not all implementors need callAsFunction translate.
    func callAsFunction(_ phraseKey: String) -> String {
        localTranslate(phraseKey)
    }
}

struct WorkTypeSummary: Identifiable {
    let workType: WorkType
    let name: String
    let jobSummary: String
    let isRequested: Bool
    let isReleasable: Bool
    let myOrgId: Int64
    let isClaimedByMyOrg: Bool

    var id: String { workType.workTypeLiteral }
}

struct OrgClaimWorkType: Identifiable {
    let orgId: Int64
    let orgName: String
    let workTypes: [WorkTypeSummary]
    let isMyOrg: Bool

    var id: Int64 { orgId }
}

struct WorkTypeProfile {
    let orgId: Int64
    let otherOrgClaims: [OrgClaimWorkType]
    let orgClaims: OrgClaimWorkType
    let unclaimed: [WorkTypeSummary]
    let releasable: [WorkTypeSummary]
    let requestable: [WorkTypeSummary]
    let releasableCount: Int
    let requestableCount: Int

    let orgName: String
    let caseNumber: String

    init(
        orgId: Int64,
        otherOrgClaims: [OrgClaimWorkType],
        orgClaims: OrgClaimWorkType,
        unclaimed: [WorkTypeSummary],
        releasable: [WorkTypeSummary],
        requestable: [WorkTypeSummary],
        orgName: String,
        caseNumber: String
    ) {
        self.orgId = orgId
        self.otherOrgClaims = otherOrgClaims
        self.orgClaims = orgClaims
        self.unclaimed = unclaimed
        self.releasable = releasable
        self.requestable = requestable
        releasableCount = releasable.count
        requestableCount = requestable.count
        self.orgName = orgName
        self.caseNumber = caseNumber
    }
}

fileprivate extension Worksite {
    func summarizeWorkTypeJobs(
        _ workTypeLookup: [String: String],
        _ workTypeLiteral: String,
        _ translate: (String) -> String,
        _ name: String
    ) -> [String?] {
        if let formData = formData {
            return formData
                .filter { formValue in workTypeLookup[formValue.key] == workTypeLiteral }
                .filter { formValue in formValue.value.isBooleanTrue }
                .map { formValue in translate(formValue.key) }
                .filter { jobName in jobName != name }
                .filter { $0.isNotBlank == true }
        }
        return []
    }
}

enum ViewCaseTabs {
    case info
    case photos
    case notes
}
