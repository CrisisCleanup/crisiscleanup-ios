import Combine
import Foundation

public protocol IncidentSelector {
    var incidentId: any Publisher<Int64, Never> { get }
    var incident: any Publisher<Incident, Never> { get }
    var incidentsData: any Publisher<IncidentsData, Never> { get }

    func setIncident(_ incident: Incident)
}

class IncidentSelectRepository: IncidentSelector {
    private let incidentsDataSubject = CurrentValueSubject<IncidentsData, Never>(LoadingIncidentsData)

    let incidentsData: any Publisher<IncidentsData, Never>

    var incident: any Publisher<Incident, Never> {
        incidentsData
            .eraseToAnyPublisher()
            .map { data in data.selected }
    }

    var incidentId: any Publisher<Int64, Never> {
        incidentsData
            .eraseToAnyPublisher()
            .map { data in data.selected.id }
    }

    private let preferencesStore: AppPreferencesDataSource

    private var incidentIdCache: Int64 = EmptyIncident.id

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        preferencesStore: AppPreferencesDataSource,
        incidentsRepository: IncidentsRepository
    ) {
        self.preferencesStore = preferencesStore

        incidentsData = incidentsDataSubject

        let accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()
        let incidentsPublisher = incidentsRepository.incidents.eraseToAnyPublisher()
        let preferencesPublisher = preferencesStore.preferences.eraseToAnyPublisher()
        Publishers.CombineLatest3(
            accountDataPublisher,
            incidentsPublisher,
            preferencesPublisher
        )
        .filter { _, incidents, _ in
            incidents.isNotEmpty
        }
        .map({ accountData, incidents, preferences in
            if accountData.id > 0,
               !accountData.isCrisisCleanupAdmin {
                let filteredIncidents = incidents.filter {
                    accountData.approvedIncidents.contains($0.id)
                }
                return (filteredIncidents, preferences)
            }

            return (incidents, preferences)
        })
        .sink { incidents, preferences in
            guard incidents.isNotEmpty else {
                return
            }

            if self.incidentIdCache == EmptyIncident.id {
                let targetId = preferences.selectedIncidentId
                var targetIncident = incidents.first { $0.id == targetId } ?? EmptyIncident
                if targetIncident.isEmptyIncident {
                    targetIncident = incidents[0]
                }

                if targetIncident.id != preferences.selectedIncidentId {
                    self.preferencesStore.setSelectedIncident(targetIncident.id)
                } else {
                    self.incidentIdCache = targetIncident.id
                    self.incidentsDataSubject.value = IncidentsData(
                        isLoading: false,
                        selected: targetIncident,
                        incidents: incidents
                    )
                }
            } else {
                self.incidentsDataSubject.value = self.incidentsDataSubject.value.copy {
                    $0.incidents = incidents
                }
            }
        }
        .store(in: &disposables)
    }

    func setIncident(_ incident: Incident) {
        preferencesStore.setSelectedIncident(incident.id)
        incidentsDataSubject.value = incidentsDataSubject.value.copy {
            $0.selected = incident
        }
    }
}
