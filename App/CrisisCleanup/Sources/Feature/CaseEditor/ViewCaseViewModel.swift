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
        // TODO: Throttle instead of debounce
            .debounce(
                for: .seconds(0.15),
                scheduler: RunLoop.current
            )
            .map { state in
                switch state {
                case .caseData(let caseData): return caseData
                default: return nil
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.caseData, on: self)
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
        // TODO: Process data and assign to workTypeProfile
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

struct WorkTypeSummary {
    let workType: WorkType
    let name: String
    let jobSummary: String
    let isRequested: Bool
    let isReleasable: Bool
    let myOrgId: Int64
    let isClaimedByMyOrg: Bool
}

struct OrgClaimWorkType {
    let orgId: Int64
    let orgName: String
    let workTypes: [WorkTypeSummary]
    let isMyOrg: Bool
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
