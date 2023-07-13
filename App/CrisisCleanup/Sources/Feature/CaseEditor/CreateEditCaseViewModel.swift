import Atomics
import Combine
import Foundation
import SwiftUI

class CreateEditCaseViewModel: ObservableObject, KeyTranslator {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private var editableWorksiteProvider: EditableWorksiteProvider
    private let translator: KeyAssetTranslator
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let incidentIdIn: Int64
    let worksiteIdIn: Int64?
    private let isCreateWorksite: Bool

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""

    @Published private(set) var isLoading = true

    @Published private(set) var isSyncing = false

    let editableViewState = EditableView()

    private let editingWorksite: AnyPublisher<Worksite, Never>

    private let uiState: AnyPublisher<CaseEditorUiState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    @Published private(set) var editSections: [String] = []
    @Published private(set) var statusOptions: [WorkTypeStatus] = []
    @Published private(set) var detailsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var workFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var hazardsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var volunteerFormFieldNode: FormFieldNode = EmptyFormFieldNode

    private let isSavingWorksite = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaving = false

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
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
        worksiteId: Int64?
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.editableWorksiteProvider = editableWorksiteProvider
        self.translator = translator
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("create-edit-case")

        translationCount = translator.translationCount

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        isCreateWorksite = worksiteId == nil

        localTranslate = { phraseKey in
            editableWorksiteProvider.translate(key: phraseKey) ?? translator.t(phraseKey)
        }

        dataLoader = CaseEditorDataLoader(
            isCreateWorksite: isCreateWorksite,
            incidentIdIn: incidentId,
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

        editingWorksite = editableWorksiteProvider.editableWorksite.eraseToAnyPublisher()

        updateHeaderTitle()
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            editableWorksiteProvider.reset(incidentIdIn)
        }

        subscribeToLoading()
        subscribeToSyncing()
        subscribeToSaving()
        subscribeToEditableState()

        subscribeToCaseData()
        subscribeToWorksiteChange()

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
        if let worksiteId = self.worksiteIdIn {
            worksiteChangeRepository.syncingWorksiteIds
                .eraseToAnyPublisher()
                .map { $0.contains(worksiteId) }
                .receive(on: RunLoop.main)
                .assign(to: \.isSyncing, on: self)
                .store(in: &subscriptions)
        }
    }

    private func subscribeToSaving() {
        isSavingWorksite.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isSaving, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToEditableState() {
        Publishers.CombineLatest(
            $isLoading.eraseToAnyPublisher(),
            $isSaving.eraseToAnyPublisher()
        )
        .map { (b0, b1) in b0 || b1 }
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)
    }

    private func subscribeToCaseData() {
        // TODO: Guard against unwanted changes after the initial load
        uiState
            .throttle(
                for: .seconds(0.1),
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
                if stateData != nil {
                    self.setFormFieldNodes()
                }
            })
            .store(in: &subscriptions)

        dataLoader.editSections
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.editSections, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToWorksiteChange() {
        dataLoader.worksiteStream
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    let worksiteId = localWorksite.worksite.id
                    self.setRecentWorksite(
                        self.incidentIdIn,
                        worksiteId
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

    private func updateHeaderTitle(_ caseNumber: String = "") {
        headerTitle = {
            if caseNumber.isBlank {
                return isCreateWorksite
                ? localTranslate("casesVue.new_case")
                : localTranslate("nav.work_view_case")
            } else {
                return "\(localTranslate("actions.view")) \(caseNumber)"
            }
        }()
    }

    private func setRecentWorksite(
        _ incidentId: Int64,
        _ worksiteId: Int64
    ) {
        if worksiteId > 0 {
            self.worksitesRepository.setRecentWorksite(
                incidentId: incidentId,
                worksiteId: worksiteId,
                viewStart: Date()
            )
        }
    }

    private func setFormFieldNodes() {
        detailsFormFieldNode = editableWorksiteProvider.getGroupNode(DetailsFormGroupKey)
        workFormFieldNode = editableWorksiteProvider.getGroupNode(WorkFormGroupKey)
        hazardsFormFieldNode = editableWorksiteProvider.getGroupNode(HazardsFormGroupKey)
        volunteerFormFieldNode = editableWorksiteProvider.getGroupNode(VolunteerReportFormGroupKey)
    }

    // MARK: KeyTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String) -> String? {
        localTranslate(phraseKey)
    }

    func t(_ phraseKey: String) -> String {
        localTranslate(phraseKey)
    }
}
