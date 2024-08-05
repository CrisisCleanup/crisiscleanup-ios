import Combine
import Foundation

class RequestRedeployViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let requestRedeployRepository: RequestRedeployRepository
    private let translator: KeyTranslator
    private let logger: AppLogger

    @Published private(set) var isLoading = true

    @Published private(set) var viewState = RequestRedeployViewState(isLoading: true, incidents: [])

    private let isRequestingRedeploySubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRequestingRedeploy = false
    private let isRedeployRequestedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRedeployRequested = false
    @Published private(set) var isTransient = false

    private let redeployErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var redeployErrorMessage = ""

    private let requestedIncidentIdsSubject = CurrentValueSubject<Set<Int64>, Never>(Set())
    @Published private(set) var requestedIncidentIds = Set<Int64>()

    private var isFirstAppear = true

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentsRepository: IncidentsRepository,
        accountDataRepository: AccountDataRepository,
        accountDataRefresher: AccountDataRefresher,
        requestRedeployRepository: RequestRedeployRepository,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.accountDataRepository = accountDataRepository
        self.accountDataRefresher = accountDataRefresher
        self.requestRedeployRepository = requestRedeployRepository
        self.translator = translator
        logger = loggerFactory.getLogger("request-redeploy")
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeIncidentData()

        if isFirstAppear {
            isFirstAppear = false

            Task {
                await accountDataRefresher.updateApprovedIncidents(true)

                requestedIncidentIdsSubject.value = await requestRedeployRepository.getRequestedIncidents()
            }
        }
    }

    private func subscribeViewState() {
        Publishers.CombineLatest(
            incidentsRepository.incidents.eraseToAnyPublisher(),
            accountDataRepository.accountData.eraseToAnyPublisher()
        )
        .map { (incidents, accountData) in
            let approvedIncidents = accountData.approvedIncidents
            let incidentOptions = incidents
                .filter { !approvedIncidents.contains($0.id) }
                .sorted { a, b in a.id > b.id }
            if incidentOptions.isEmpty {
                let orgId = accountData.org.id
                let message = "Request redeploy has no incidents. Org \(orgId)"
                self.logger.logError(GenericError(message))
            }
            return RequestRedeployViewState(isLoading: false, incidents: incidentOptions)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.viewState, on: self)
        .store(in: &subscriptions)

        $viewState
            .map { $0.isLoading }
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        isRequestingRedeploySubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRequestingRedeploy, on: self)
            .store(in: &subscriptions)

        isRedeployRequestedSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRedeployRequested, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $viewState,
            $isRequestingRedeploy
        )
        .map { (state, b0) in state.isLoading || b0 }
        .receive(on: RunLoop.main)
        .assign(to: \.isTransient, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeIncidentData() {
        requestedIncidentIdsSubject
            .receive(on: RunLoop.main)
            .assign(to: \.requestedIncidentIds, on: self)
            .store(in: &subscriptions)
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    func requestRedeploy(incident: Incident) {
        if incident == EmptyIncident {
            return
        }

        if isRequestingRedeploySubject.value {
            return
        }
        isRequestingRedeploySubject.value = true

        redeployErrorMessageSubject.value = ""

        Task {
            do {
                defer {
                    isRequestingRedeploySubject.value = false
                }

                let isRequested = await requestRedeployRepository.requestRedeploy(incident.id)
                if isRequested {
                    isRedeployRequestedSubject.value = true
                } else {
                    // TODO: More informative error state where possible
                    redeployErrorMessageSubject.value =
                    translator.t("info.request_redeploy_failed")
                        .replacingOccurrences(of: "{incident_name}", with: incident.shortName)
                }
            }
        }
    }
}

struct RequestRedeployViewState {
    let isLoading : Bool
    let incidents: [Incident]
}
