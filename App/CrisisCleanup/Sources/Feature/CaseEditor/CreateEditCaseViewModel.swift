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
    private let networkMonitor: NetworkMonitor
    private let inputValidator: InputValidator
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let incidentIdIn: Int64
    let worksiteIdIn: Int64?
    private let isCreateWorksite: Bool

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""

    let visibleNoteCount = 3

    @Published private(set) var isOnline = true

    @Published private(set) var isLoading = true

    @Published private(set) var isSyncing = false

    @Published private(set) var areEditorsReady = false

    let editableViewState = EditableView()

    private let editingWorksite: AnyPublisher<Worksite, Never>

    private let uiState: AnyPublisher<CaseEditorUiState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    // For preventing unwanted editor reloads
    private var editorSetTime: Date?
    private let editorSetWindow: Double

    @Published private(set) var editSections: [String] = []
    @Published private(set) var statusOptions: [WorkTypeStatus] = []
    @Published private(set) var detailsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var workFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var hazardsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var volunteerFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var groupFormFieldNodes: [FormFieldNode] = []

    @Published private(set) var flagTranslateKeys: [String] = []

    let propertyInputData = PropertyInputData()
    let locationInputData = LocationInputData()
    @Published private(set) var isHighPriority = false
    @Published private(set) var isAssignedToOrgMember = false
    @Published private(set) var worksiteNotes = [WorksiteNote]()
    @Published var binaryFormData = ObservableBoolDictionary()
    @Published var contentFormData = ObservableStringDictionary()

    @Published private(set) var showInvalidWorksiteSave = false
    @Published private(set) var invalidWorksiteInfo = InvalidWorksiteInfo()

    @Published private(set) var navigateBack = false

    private let isSavingWorksite = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaving = false

    @Published private(set) var editIncidentWorksite = (EmptyIncident.id, EmptyWorksite.id)

    @Published private(set) var changeWorksiteIncidentId = EmptyIncident.id
    @Published private(set) var changeExistingWorksite = (EmptyIncident.id, EmptyWorksite.id)
    private var saveChangeIncident = EmptyIncident
    private var changingIncidentWorksite = EmptyWorksite

    @Published private(set) var showClaimAndSave = true

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
        inputValidator: InputValidator,
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
        self.networkMonitor = networkMonitor
        self.inputValidator = inputValidator
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

        editorSetWindow = isCreateWorksite ? 0.05.seconds : 0.6.seconds

        updateHeaderTitle()
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            let incidentChangeData = editableWorksiteProvider.takeIncidentChanged()
            changingIncidentWorksite = incidentChangeData?.worksite ?? EmptyWorksite

            editableWorksiteProvider.reset(incidentIdIn)
        }

        subscribeOnline()
        subscribeLoading()
        subscribeSyncing()
        subscribeSaving()
        subscribeEditableState()

        subscribeCaseData()
        subscribeWorksiteChange()

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

    private func subscribeOnline() {
        networkMonitor.isOnline
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isOnline, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLoading() {
        dataLoader.isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSyncing() {
        if let worksiteId = self.worksiteIdIn {
            worksiteChangeRepository.syncingWorksiteIds
                .eraseToAnyPublisher()
                .map { $0.contains(worksiteId) }
                .receive(on: RunLoop.main)
                .assign(to: \.isSyncing, on: self)
                .store(in: &subscriptions)
        }
    }

    private func subscribeSaving() {
        isSavingWorksite.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isSaving, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeEditableState() {
        Publishers.CombineLatest3(
            $isLoading,
            $isSaving,
            $areEditorsReady
        )
        .map { (b0, b1, editorsReady) in b0 || b1 || !editorsReady}
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)

        if !isCreateWorksite {
            editingWorksite.map {
                $0.workTypes.first(where: { workType in workType.orgClaim == nil }) != nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.showClaimAndSave, on: self)
            .store(in: &subscriptions)
        }
    }

    private func subscribeCaseData() {
        uiState
            .compactMap { state in
                let result: CaseEditorCaseData? = {
                    switch state {
                    case .caseData(let caseData): return caseData
                    default: return nil
                    }
                }()
                return result
            }
            .filter { stateData in
                var passesFilter = false
                if stateData?.isNetworkLoadFinished == true {
                    if self.editorSetTime == nil ||
                        self.editorSetTime!.distance(to: Date.now) < self.editorSetWindow {
                        passesFilter = true
                    }
                    if passesFilter {
                        self.editorSetTime = Date.now
                    }
                }
                return passesFilter
            }
            .debounce(
                for: .seconds(editorSetWindow * 1.5),
                scheduler: RunLoop.current
            )
            .receive(on: RunLoop.main)
            .sink(receiveValue: { stateData in
                if self.changingIncidentWorksite != EmptyWorksite {
                    self.editableWorksiteProvider.editableWorksite.value = self.changingIncidentWorksite
                }

                self.caseData = stateData
                self.statusOptions = stateData!.statusOptions
                self.setFormFieldNodes()

                var flagOptionTranslationKeys = [
                    "caseForm.address_problems",
                    "flag.flag_high_priority"
                ]
                if self.isCreateWorksite {
                    flagOptionTranslationKeys.append("actions.member_of_my_org")
                }
                self.flagTranslateKeys = flagOptionTranslationKeys

                self.loadInitialWorksite()

                self.areEditorsReady = true
            })
            .store(in: &subscriptions)

        dataLoader.editSections
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.editSections, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeWorksiteChange() {
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
        if incidentId > 0 && worksiteId > 0 {
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
        groupFormFieldNodes = [
            detailsFormFieldNode,
            workFormFieldNode,
            hazardsFormFieldNode,
            volunteerFormFieldNode
        ]
    }

    private var formFieldsInputData = FormFieldsInputData()
    private func loadInitialWorksite() {
        let worksite = editableWorksiteProvider.editableWorksite.value

        propertyInputData.load(worksite)
        locationInputData.load(worksite)
        isHighPriority = worksite.hasHighPriorityFlag
        isAssignedToOrgMember = worksite.isAssignedToOrgMember
        worksiteNotes.append(contentsOf: worksite.notes)

        if !isCreateWorksite {
            formFieldsInputData = loadFormFieldsInputData(editableWorksiteProvider)
            for binaryField in formFieldsInputData.binaryFields {
                binaryFormData[binaryField] = true
            }
            for (key, value) in formFieldsInputData.contentFields {
                contentFormData[key] = value
            }
        }
    }

    func scheduleSync() {
        if !isSyncing,
           let worksiteId = worksiteIdIn {
            syncPusher.appPushWorksite(worksiteId)
        }
    }

    private func validateWorksite() -> Bool {
        if !propertyInputData.validate(inputValidator, t) {
            return false
        }

        if !locationInputData.validate(t) {
            return false
        }

        // TODO: Validate remaining

        return true
    }

    private func onIncidentChange() {
        // TODO: Do
    }

    func saveChanges(
        _ claimUnclaimed: Bool,
        backOnSuccess: Bool = true
    ) {
        // TODO: Do
    }

    private func setInvalidSection() {
        // TODO: Do
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

enum WorksiteSection {
    case none,
         property,
         location,
         locationAddress,
         details,
         workType,
         hazards,
         volunteerReport
}

struct InvalidWorksiteInfo {
    let invalidSection: WorksiteSection
    let message: String

    init(
        _ invalidSection: WorksiteSection = .none,
        _ message: String = ""
    ) {
        self.invalidSection = invalidSection
        self.message = message
    }
}
