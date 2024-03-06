import Combine

class RequestRedeployViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let requestRedeployRepository: RequestRedeployRepository
    private let translator: KeyTranslator
    private let logger: AppLogger

    @Published private(set) var isLoading = false

    private let isRequestingRedeploySubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRequestingRedeploy = false
    private let isRedeployRequestedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRedeployRequested = false

    @Published private(set) var redeployErrorMessage = ""

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

        redeployErrorMessage = ""

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
                    redeployErrorMessage =
                    translator.t("~~Request redeploy of {incident_name} failed.")
                        .replacingOccurrences(of: "{incident_name}", with: incident.shortName)
                }
            }
        }
    }
}
