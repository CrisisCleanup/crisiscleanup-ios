import Combine
import Foundation

class ViewListViewModel: ObservableObject {
    private let listsRepository: ListsRepository
    private let incidentsRepository: IncidentsRepository
    private let incidentSelector: IncidentSelector
    let phoneNumberParser: PhoneNumberParser
    private let translator: KeyTranslator
    private let logger: AppLogger

    let listId: Int64

    @Published private(set) var viewState = ViewListViewState(isLoading: true)

    @Published private(set) var showLoading = true

    private let isConfirmingOpenWorksiteSubject = CurrentValueSubject<Bool, Never>(false)
    private let openWorksiteIdSubject = CurrentValueSubject<ExistingWorksiteIdentifier, Never>(ExistingWorksiteIdentifierNone)
    @Published private(set) var openWorksiteId = ExistingWorksiteIdentifierNone
    private let openWorksiteErrorSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var openWorksiteError = ""

    private let isChangingIncidentSubject = CurrentValueSubject<Bool, Never>(false)
    private var openWorksiteChangeIncident = EmptyIncident
    private var pendingOpenWorksite = EmptyWorksite
    private let changeIncidentConfirmMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var changeIncidentConfirmMessage = ""

    @Published private(set) var screenTitle = ""

    private var isFirstVisible = true

    private var subscriptions = Set<AnyCancellable>()

    init(
        listsRepository: ListsRepository,
        incidentsRepository: IncidentsRepository,
        incidentSelector: IncidentSelector,
        phoneNumberParser: PhoneNumberParser,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory,
        listId: Int64
    ) {
        self.listsRepository = listsRepository
        self.incidentsRepository = incidentsRepository
        self.incidentSelector = incidentSelector
        self.phoneNumberParser = phoneNumberParser
        self.translator = translator
        logger = loggerFactory.getLogger("list")
        self.listId = listId
    }

    func onViewAppear() {
        if isFirstVisible {
            isFirstVisible = false

            Task {
                await listsRepository.refreshList(listId)
            }
        }

        subscribeViewState()
        subscribeOpenWorksite()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        listsRepository.streamList(listId)
            .eraseToAnyPublisher()
            .asyncMap { list in
                if (list.id == EmptyList.id) {
                    let listNotFound = self.translator.t("list.not_found_deleted")
                    return ViewListViewState(errorMessage: listNotFound)
                }

                let lookup = await self.listsRepository.getListObjectData(list)
                var objectIds = list.objectIds
                if list.model == .list {
                    objectIds = objectIds.filter { $0 != list.networkId }
                }
                let objectData = objectIds.map {
                    lookup[$0]
                }
                return ViewListViewState(list: list, objectData: objectData)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.viewState, on: self)
            .store(in: &subscriptions)

        $viewState
            .map {
                if $0.list.id != EmptyList.id,
                   $0.list.name.isNotBlank {
                    return $0.list.name
                }

                return self.translator.t("list.list")
            }
            .receive(on: RunLoop.main)
            .assign(to: \.screenTitle, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            $viewState,
            isConfirmingOpenWorksiteSubject,
            isChangingIncidentSubject
        )
        .map { state, b1, b2 in
            state.isLoading || b1 || b2
        }
        .receive(on: RunLoop.main)
        .assign(to: \.showLoading, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeOpenWorksite() {
        openWorksiteIdSubject
            .receive(on: RunLoop.main)
            .assign(to: \.openWorksiteId, on: self)
            .store(in: &subscriptions)

        openWorksiteErrorSubject
            .receive(on: RunLoop.main)
            .assign(to: \.openWorksiteError, on: self)
            .store(in: &subscriptions)

        changeIncidentConfirmMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.changeIncidentConfirmMessage, on: self)
            .store(in: &subscriptions)
    }

    func clearOpenWorksiteError() {
        openWorksiteErrorSubject.value = ""
    }

    func clearPendingWorksiteChange() {
        openWorksiteIdSubject.value = ExistingWorksiteIdentifierNone
    }

    func onConfirmChangeIncident() {
        if isChangingIncidentSubject.value {
            return
        }

        let changeIncident = openWorksiteChangeIncident
        let changeWorksite = pendingOpenWorksite
        do {
            defer {
                clearChangeIncident()
            }

            if changeIncident == EmptyIncident ||
                changeWorksite == EmptyWorksite {
                return
            }
        }

        isChangingIncidentSubject.value = true
        Task {
            do {
                defer {
                    isChangingIncidentSubject.value = false
                }

                incidentSelector.setIncident(changeIncident)
                openWorksiteIdSubject.value = ExistingWorksiteIdentifier(
                    incidentId: changeIncident.id,
                    worksiteId: changeWorksite.id
                )
            }
        }
    }

    func clearChangeIncident() {
        openWorksiteChangeIncident = EmptyIncident
        pendingOpenWorksite = EmptyWorksite
        changeIncidentConfirmMessageSubject.value = ""
    }

    func onOpenWorksite(_ worksite: Worksite) {
        if worksite == EmptyWorksite ||
            isConfirmingOpenWorksiteSubject.value ||
            isChangingIncidentSubject.value {
            return
        }
        isConfirmingOpenWorksiteSubject.value = true

        let list = self.viewState.list
        Task {
            do {
                defer {
                    isConfirmingOpenWorksiteSubject.value = false
                }

                if list.id != EmptyList.id {
                    let targetIncidentId = worksite.incidentId
                    if list.incident?.id == targetIncidentId {
                        let targetWorksiteId = ExistingWorksiteIdentifier(
                            incidentId: targetIncidentId,
                            worksiteId: worksite.id
                        )
                        let selectedIncident = try await incidentSelector.incident.eraseToAnyPublisher().asyncFirst()
                        if targetIncidentId == selectedIncident.id {
                            openWorksiteIdSubject.value = targetWorksiteId
                        } else {
                            if let cachedIncident = try self.incidentsRepository.getIncident(targetIncidentId) {
                                openWorksiteChangeIncident = cachedIncident
                                pendingOpenWorksite = worksite
                                changeIncidentConfirmMessageSubject.value =
                                translator.t("list.change_incident_confirm")
                                    .replacingOccurrences(of: "{incident_name}", with: cachedIncident.shortName)
                                    .replacingOccurrences(of: "{case_number}", with: worksite.caseNumber)
                            } else {
                                openWorksiteErrorSubject.value = translator.t("list.incident_not_downloaded_error")
                            }
                        }
                    } else {
                        openWorksiteErrorSubject.value = translator.t("list.cannot_access_case_wrong_incident")
                            .replacingOccurrences(of: "{case_number}", with: worksite.caseNumber)
                            .replacingOccurrences(of: "{incident_name}", with: list.incident?.shortName ?? "")
                            .trim()
                    }
                }
            } catch {
                logger.logError(error)
            }
        }
    }
}

internal struct ViewListViewState {
    let isLoading: Bool
    let list: CrisisCleanupList
    let objectData: [Any?]
    let errorMessage: String

    init(
        isLoading: Bool = false,
        list: CrisisCleanupList = EmptyList,
        objectData: [Any?] = [],
        errorMessage: String = ""
    ) {
        self.isLoading = isLoading
        self.list = list
        self.objectData = objectData
        self.errorMessage = errorMessage
    }
}
