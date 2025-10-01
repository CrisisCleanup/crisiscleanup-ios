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

    @Published private(set) var viewState = RequestRedeployViewState(
        isLoading: true,
        incidents: [],
        approvedIncidentIds: [],
        requestedIncidentIds: []
    )

    private let isRequestingRedeploySubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRequestingRedeploy = false
    private let isRedeployRequestedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRedeployRequested = false
    @Published private(set) var isTransient = false

    private let redeployErrorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var redeployErrorMessage = ""

    private let incidentsSubject = CurrentValueSubject<[IncidentIdNameType]?, Never>(nil)
    private let requestedIncidentIdsSubject = CurrentValueSubject<Set<Int64>, Never>(Set())

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

        if isFirstAppear {
            isFirstAppear = false

            Task {
                await accountDataRefresher.updateProfileIncidentsData(true)

                requestedIncidentIdsSubject.value = await requestRedeployRepository.getRequestedIncidents()

                incidentsSubject.value = await incidentsRepository.getIncidentsList()
            }
        }
    }

    private func subscribeViewState() {
        Publishers.CombineLatest3(
            incidentsSubject,
            accountDataRepository.accountData.eraseToAnyPublisher(),
            requestedIncidentIdsSubject
        )
        .filter { (incidents, _, _) in
            incidents != nil
        }
        .map { (incidents, accountData, requestedIds) in
            let approvedIds = accountData.approvedIncidents
            return RequestRedeployViewState(
                isLoading: false,
                incidents: incidents!,
                approvedIncidentIds: approvedIds,
                requestedIncidentIds: requestedIds
            )
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

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    func requestRedeploy(incident: IncidentIdNameType) {
        if incident == EmptyIncidentIdNameType {
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
    let incidents: [IncidentIdNameType]
    let approvedIncidentIds: Set<Int64>
    let requestedIncidentIds: Set<Int64>
}
