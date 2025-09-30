import Combine
import CombineExt
import Foundation

// sourcery: AutoMockable
public protocol IncidentSelector {
    var incidentId: any Publisher<Int64, Never> { get }
    var incident: any Publisher<Incident, Never> { get }
    var incidentsData: any Publisher<IncidentsData, Never> { get }

    func selectIncident(_ incident: Incident)
    func submitIncidentChange(_ incident: Incident) async -> Bool
}

class IncidentSelectRepository: IncidentSelector {
    private let preferencesStore: AppPreferencesDataSource
    private let logger: AppLogger

    private let incidentsDataSubject = CurrentValueRelay<IncidentsData>(LoadingIncidentsData)

    private let incidentsSource: AnyPublisher<[Incident], Never>

    let incidentsData: any Publisher<IncidentsData, Never>

    let incident: any Publisher<Incident, Never>

    let incidentId: any Publisher<Int64, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        preferencesStore: AppPreferencesDataSource,
        incidentsRepository: IncidentsRepository,
        loggerFactory: AppLoggerFactory,
    ) {
        self.preferencesStore = preferencesStore
        logger = loggerFactory.getLogger("incident-data")

        incidentsData = incidentsDataSubject.removeDuplicates()
        let dataSource = incidentsData.eraseToAnyPublisher().replay1()
        incident = dataSource.map { $0.selected }
        incidentId = dataSource.map { $0.selectedId }

        let accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()
        let incidentsPublisher = incidentsRepository.incidents.eraseToAnyPublisher()
        let preferencesPublisher = preferencesStore.preferences.eraseToAnyPublisher()
        let isLoadingIncidents = incidentsRepository.isLoading.eraseToAnyPublisher()

        incidentsSource = Publishers.CombineLatest(
            incidentsPublisher,
            accountDataPublisher,
        )
        .map { incidents, accountData in
            accountData.filterApproved(incidents)
        }
        .eraseToAnyPublisher()

        let preferencesIncidentId = preferencesPublisher.map {
            $0.selectedIncidentId
        }

        let selectedIncident = Publishers.CombineLatest(
            preferencesIncidentId,
            incidentsSource,
        )
            .map { selectedId, incidents in
                incidents.first(where: { $0.id == selectedId })
                ?? EmptyIncident
            }

        Publishers.CombineLatest3(
            isLoadingIncidents,
            incidentsSource,
            selectedIncident,
        )
        .map { isLoading, incidents, selected in
            let loading = isLoading && incidents.isEmpty
            return IncidentsData(
                isLoading: loading,
                selected: selected,
                incidents: incidents,
            )
        }
        .sink {
            self.incidentsDataSubject.accept($0)
        }
        .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    func selectIncident(_ incident: Incident) {
        Task {
            await submitIncidentChange(incident)
        }
    }

    func submitIncidentChange(_ incident: Incident) async -> Bool {
        let incidentId = incident.id
        do {
            let incidents = try await incidentsSource.asyncFirst()
            if let incident = incidents.first(where: { $0.id == incidentId }) {
                preferencesStore.setSelectedIncident(incident.id)
            }
            return true
        } catch {
            logger.logError(error)
        }
        return false
    }
}
