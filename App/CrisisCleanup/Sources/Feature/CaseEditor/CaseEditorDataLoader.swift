import Atomics
import Combine
import Foundation

internal class CaseEditorDataLoader {
    private let isCreateWorksite: Bool
    private let worksitesRepository: WorksitesRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let editableWorksiteProvider: EditableWorksiteProvider
    private let incidentRefresher: IncidentRefresher
    private let languageRefresher: LanguageRefresher
    private let workTypeStatusRepository: WorkTypeStatusRepository
    private let logger: AppLogger

    private let logDebug: Bool

    private let editSectionsSubject = CurrentValueSubject<[String], Never>([])
    let editSections: any Publisher<[String], Never>

    private let incidentFieldLookupSubject = CurrentValueSubject<[String: GroupSummaryFieldLookup], Never>([:])
    let incidentFormFieldLookup: any Publisher<[String: GroupSummaryFieldLookup], Never>
    private let workTypeGroupChildrenLookupSubject = CurrentValueSubject<[String: Set<String>], Never>([:])
    let workTypeGroupChildrenLookup: any Publisher<[String: Set<String>], Never>
    private var workTypeGroupFormFields = [String: IncidentFormField]()

    private let dataLoadCountStream = CurrentValueSubject<Int, Never>(0)
    private let isRefreshingIncident = CurrentValueSubject<Bool, Never>(false)
    private let isRefreshingWorksite = CurrentValueSubject<Bool, Never>(false)

    let isLoading: any Publisher<Bool, Never>

    private let worksiteIdSubject = CurrentValueSubject<Int64?, Never>(nil)
    let worksiteStream: AnyPublisher<LocalWorksite?, Never>

    private let isInitiallySynced = ManagedAtomic(false)
    private let isWorksitePulledSubject = CurrentValueSubject<Bool, Never>(false)

    private let incidentDataStream: AnyPublisher<IncidentBoundsPair?, Never>
    private let organizationStream: AnyPublisher<OrgData, Never>
    private let workTypeStatusStream: AnyPublisher<[WorkTypeStatus], Never>
    private let isOnlinePublisher: AnyPublisher<Bool, Never>
    private let keyTranslator: KeyTranslator

    private let uiStateSubject = CurrentValueSubject<CaseEditorUiState, Never>(CaseEditorUiState.loading)
    let uiState: any Publisher<CaseEditorUiState, Never>

    private let latestDataPublisher = LatestAsyncThrowsPublisher<CaseEditorUiState>()

    private var disposables = Set<AnyCancellable>()

    init(
        isCreateWorksite: Bool,
        incidentIdIn: Int64,
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        incidentRefresher: IncidentRefresher,
        incidentBoundsProvider: IncidentBoundsProvider,
        worksitesRepository: WorksitesRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        keyTranslator: KeyTranslator,
        languageRefresher: LanguageRefresher,
        workTypeStatusRepository: WorkTypeStatusRepository,
        editableWorksiteProvider: EditableWorksiteProvider,
        networkMonitor: NetworkMonitor,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
        debugTag: String = ""
    ) {
        self.isCreateWorksite = isCreateWorksite
        self.worksitesRepository = worksitesRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.editableWorksiteProvider = editableWorksiteProvider
        self.incidentRefresher = incidentRefresher
        self.languageRefresher = languageRefresher
        self.workTypeStatusRepository = workTypeStatusRepository
        logger = loggerFactory.getLogger(debugTag)

        logDebug = appEnv.isDebuggable && debugTag.isNotBlank

        editSections = editSectionsSubject

        incidentFormFieldLookup = incidentFieldLookupSubject
        workTypeGroupChildrenLookup = workTypeGroupChildrenLookupSubject

        isLoading = Publishers.CombineLatest(
            isRefreshingIncident.eraseToAnyPublisher(),
            isRefreshingWorksite.eraseToAnyPublisher()
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)

        organizationStream = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map { $0.org }
            .removeDuplicates()
            .eraseToAnyPublisher()

        incidentDataStream = incidentsRepository.streamIncident(incidentIdIn)
            .eraseToAnyPublisher()
            .removeDuplicates()
            .map { incident in
                let publisher: AnyPublisher<IncidentBoundsPair?, Never>
                if let incident = incident {
                    publisher = incidentBoundsProvider.mapIncidentBounds(incident)
                        .map { bounds in
                            IncidentBoundsPair(incident: incident, bounds: bounds)
                        }
                        .eraseToAnyPublisher()
                } else {
                    publisher = Just<IncidentBoundsPair?>(nil)
                        .eraseToAnyPublisher()
                }
                return publisher
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()

        worksiteStream = worksiteIdSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
            .map { worksiteId in
                if worksiteId == nil || worksiteId! <= 0 {
                    return Just<LocalWorksite?>(nil)
                        .eraseToAnyPublisher()
                } else {
                    return worksitesRepository.streamLocalWorksite(worksiteId!)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()

        workTypeStatusStream = workTypeStatusRepository.workTypeStatusOptions
            .eraseToAnyPublisher()

        uiState = uiStateSubject
            .receive(on: RunLoop.main)

        isOnlinePublisher = networkMonitor.isOnline.eraseToAnyPublisher()

        self.keyTranslator = keyTranslator
    }

    func loadData(
        incidentIdIn: Int64,
        worksiteIdIn: Int64?,
        translate: @escaping (String) -> String
    ) {
        Task {
            self.isRefreshingIncident.value = true
            do {
                defer { self.isRefreshingIncident.value = false }
                await incidentRefresher.pullIncident(incidentIdIn)

                // TODO: Use a better syncing mechanisim after refreshing and local data query
                do {
                    try await Task.sleep(for: .seconds(0.5))
                } catch {}
            }
            await languageRefresher.pullLanguages()
            await workTypeStatusRepository.loadStatuses()
        }

        worksiteStream
            .filter { $0 != nil }
            .sink(receiveValue: {
                if let localWorksite = $0 {
                    if self.isInitiallySynced.exchange(true, ordering: .acquiringAndReleasing) {
                        return
                    }

                    do {
                        defer {
                            self.isRefreshingWorksite.value = false
                            self.isWorksitePulledSubject.value = true
                        }

                        let worksite = localWorksite.worksite
                        let networkId = worksite.networkId
                        if worksite.id > 0 &&
                            (networkId > 0 || localWorksite.localChanges.isLocalModified) {
                            self.isRefreshingWorksite.value = true
                            let isSynced = await self.worksiteChangeRepository.trySyncWorksite(worksite.id)
                            if isSynced && networkId > 0 {
                                try await self.worksitesRepository.pullWorkTypeRequests(networkId)
                            }
                        }
                    } catch {
                        self.logger.logError(error)
                    }
                }
            })
            .store(in: &disposables)

        Publishers.CombineLatest(
            Publishers.CombineLatest3(
                dataLoadCountStream,
                organizationStream,
                workTypeStatusStream
            ),
            Publishers.CombineLatest4(
                incidentDataStream,
                isRefreshingIncident,
                worksiteStream,
                isWorksitePulledSubject.eraseToAnyPublisher()
            )
        )
        .map { (a, b) in
            CaseEditorStateData(
                dataLoadCount: a.0,
                organization: a.1,
                statuses: a.2,
                incidentData: b.0,
                isPullingIncident: b.1,
                worksite: b.2,
                isPulled: b.3
            )
        }
        .filter { $0.incidentData != nil }
        .debounce(for: .seconds(0.15), scheduler: RunLoop.current)
        .map { stateData in self.latestDataPublisher.publisher {
            let organization = stateData.organization
            let workTypeStatuses = stateData.statuses
            let incidentData = stateData.incidentData!

            let worksiteId = self.worksiteIdSubject.value ?? 0

            if organization.id <= 0 {
                self.logger.logError(GenericError("Organization \(organization) is not set when editing worksite \(worksiteId)."))
                return CaseEditorUiState.error(translate("info.organization_issue_log_out"))
            }

            let incident = incidentData.incident
            let bounds = incidentData.bounds
            let pullingIncident = stateData.isPullingIncident

            if !pullingIncident && incident.formFields.isEmpty {
                self.logger.logError(GenericError("Incident \(incidentIdIn) is missing form fields when editing worksite \(worksiteId)."))
                let errorMessage = translate("info.incident_loading")
                    .replacingOccurrences(of: "{name}", with: incident.name)
                return CaseEditorUiState.error(errorMessage)
            }

            if bounds.locations.isEmpty {
                self.logger.logError(GenericError("Incident \(incident.id) \(incident.name) is lacking locations."))
                let errorMessage = translate("info.current_incident_problem")
                    .replacingOccurrences(of: "{name}", with: incident.name)
                return CaseEditorUiState.error(errorMessage)
            }

            let localWorksite = stateData.worksite
            let isPulled = stateData.isPulled

            let loadedWorksite = localWorksite?.worksite
            let isOnline: Bool
            do {
                isOnline = try await self.isOnlinePublisher.asyncFirst()
            } catch {
                isOnline = false
                self.logger.logError(error)
            }
            var worksiteState = loadedWorksite ?? EmptyWorksite.copy {
                $0.incidentId = incidentIdIn
                $0.autoContactFrequencyT = AutoContactFrequency.often.literal
                // TODO: Toggle address input rather than set wrong location flag
                $0.flags = isOnline ? EmptyWorksite.flags : [WorksiteFlag.wrongLocation()]
            }

            try Task.checkCancellation()

            with(self.editableWorksiteProvider) { ewp in
                ewp.incident = incident

                if (loadedWorksite != nil && ewp.takeStale()) || ewp.formFields.isEmpty {
                    ewp.formFields = FormFieldNode.buildTree(
                        incident.formFields,
                        self.keyTranslator
                    )
                    // TODO: Test this produces a flat array
                    .map { $0.flatten() }

                    ewp.formFieldTranslationLookup = incident.formFields
                        .filter { $0.fieldKey.isNotBlank && $0.label.isNotBlank }
                        .associate { ($0.fieldKey, $0.label) }

                    let workTypeFormFields: [FormFieldNode]
                    if let workFormFields = ewp.formFields.first(where: { $0.fieldKey == WorkFormGroupKey }) {
                        workTypeFormFields = workFormFields.children.filter { $0.parentKey == WorkFormGroupKey }
                    } else {
                        workTypeFormFields = []
                    }
                    self.workTypeGroupChildrenLookupSubject.value = workTypeFormFields.associate { f in
                        (f.fieldKey, Set(f.children.map { c in c.fieldKey }) )
                    }
                    self.workTypeGroupFormFields = workTypeFormFields.associate { f in
                        let formField = incident.formFieldLookup[f.fieldKey]!
                        return (formField.selectToggleWorkType, formField)
                    }

                    ewp.workTypeTranslationLookup = workTypeFormFields.associate { f in
                        let name = ewp.formFieldTranslationLookup[f.fieldKey] ?? f.fieldKey
                        return (f.formField.selectToggleWorkType, name)
                    }

                    let localTranslate = { s in translate(s) }
                    self.incidentFieldLookupSubject.value = ewp.formFields.associate { node in
                        let groupFieldMap = node.children.associate { child in
                            let label = child.formField.label
                            return (child.fieldKey, label.isEmpty ? localTranslate(child.fieldKey) : label)
                        }
                        let flattened = node.children
                            .map { $0.options }
                            .joined()
                        let groupOptionsMap = Array(flattened).associate { ($0.key, $0.value) }
                        return (
                            node.fieldKey,
                            GroupSummaryFieldLookup(
                                fieldMap: groupFieldMap,
                                optionTranslations: groupOptionsMap
                            )
                        )
                    }
                }

                if self.editSectionsSubject.value.isEmpty && ewp.formFields.isNotEmpty {
                    var editSections = [translate("caseForm.property_information")]
                    let requiredGroups: Set = ["workInfo"]
                    ewp.formFields.map { node in
                        let label = node.formField.label
                        let isRequired = requiredGroups.contains(node.formField.group)
                        return isRequired ? "\(label) *" : label
                    }
                    .forEach {
                        editSections.append($0)
                    }
                    self.editSectionsSubject.value = editSections
                }

                var updatedFormData = [String: WorksiteFormValue]()
                if let worksiteFormData = worksiteState.formData {
                    updatedFormData = worksiteFormData
                }
                let workTypeGroups = Set(
                    updatedFormData.keys
                        .filter { incident.workTypeLookup[$0] != nil }
                        .compactMap { incident.formFieldLookup[$0]?.parentKey }
                )
                workTypeGroups.forEach {
                    updatedFormData[$0] = WorksiteFormValue.trueValue
                }
                worksiteState.workTypes.forEach { workType in
                    if let formField = self.workTypeGroupFormFields[workType.workTypeLiteral] {
                        updatedFormData[formField.fieldKey] = WorksiteFormValue.trueValue
                    }
                }
                if updatedFormData.count != worksiteState.formData?.count {
                    worksiteState = worksiteState.copy {
                        $0.formData = updatedFormData
                    }
                }

                if !ewp.isStale || loadedWorksite != nil {
                    ewp.editableWorksite.value = worksiteState
                }
                ewp.incidentBounds = bounds
            }

            try Task.checkCancellation()

            var isEditingAllowed = self.editSectionsSubject.value.isNotEmpty && workTypeStatuses.isNotEmpty
            var isNetworkLoadFinished = true
            var isLocalLoadFinished = true
            if !self.isCreateWorksite {
                isEditingAllowed = isEditingAllowed && localWorksite != nil
                isNetworkLoadFinished = isEditingAllowed && isPulled
                isLocalLoadFinished = isNetworkLoadFinished && worksiteState.formData?.isNotEmpty == true
            }
            let isTranslationUpdated = self.editableWorksiteProvider.formFieldTranslationLookup.isNotEmpty
            let isPendingSync = !isLocalLoadFinished ||
            localWorksite?.localChanges.isLocalModified ?? false
            return CaseEditorUiState.caseData(
                CaseEditorCaseData(
                    orgId: organization.id,
                    isEditingAllowed: isEditingAllowed,
                    statusOptions: workTypeStatuses,
                    worksite: worksiteState,
                    incident: incident,
                    localWorksite: localWorksite,
                    isNetworkLoadFinished: isNetworkLoadFinished,
                    isLocalLoadFinished: isLocalLoadFinished,
                    isTranslationUpdated: isTranslationUpdated,
                    isPendingSync: isPendingSync
                )
            )
        }}
        .switchToLatest()
        .sink(receiveValue: { state in
            self.uiStateSubject.value = state
        })
        .store(in: &disposables)

        worksiteIdSubject.value = worksiteIdIn
    }

    func unsubscribe() {
        _ = cancelSubscriptions(disposables)
    }

    func reloadData(_ worksiteId: Int64) {
        editableWorksiteProvider.setStale()
        worksiteIdSubject.value = worksiteId
        dataLoadCountStream.value += 1
    }
}

private struct CaseEditorStateData: Equatable {
    let dataLoadCount: Int
    let organization: OrgData
    let statuses: [WorkTypeStatus]
    let incidentData: IncidentBoundsPair?
    let isPullingIncident: Bool
    let worksite: LocalWorksite?
    let isPulled: Bool
}

struct CaseEditorCaseData {
    let orgId: Int64
    let isEditingAllowed: Bool
    let statusOptions: [WorkTypeStatus]
    let worksite: Worksite
    let incident: Incident
    let localWorksite: LocalWorksite?
    let isNetworkLoadFinished: Bool
    let isLocalLoadFinished: Bool
    let isTranslationUpdated: Bool
    let isPendingSync: Bool
}

enum CaseEditorUiState {
    case loading,
         caseData(_ caseData: CaseEditorCaseData),
         error(_ errorMessage: String)
}

private struct IncidentBoundsPair: Equatable {
    let incident: Incident
    let bounds: IncidentBounds

    init(incident: Incident, bounds: IncidentBounds) {
        self.incident = incident
        self.bounds = bounds
    }
}
