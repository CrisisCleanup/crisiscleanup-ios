import Combine
import Foundation

public protocol IncidentSelector {
    var incidentId: any Publisher<Int64, Never> { get }
    var incident: any Publisher<Incident, Never> { get }
    var incidentsData: any Publisher<IncidentsData, Never> { get }

    func setIncident(incident: Incident)
}

class IncidentSelectRepository: IncidentSelector {
    private let incidentsDataSubject = CurrentValueSubject<IncidentsData, Never>(LoadingIncidentsData)

    let incidentsData: any Publisher<IncidentsData, Never>

    let incident: any Publisher<Incident, Never>

    let incidentId: any Publisher<Int64, Never>

    private let preferencesStore: AppPreferencesDataStore

    private let incidentLock = NSLock()

    private var incidentIdCache: Int64 = EmptyIncident.id

    private var disposables = Set<AnyCancellable>()

    init(
        preferencesStore: AppPreferencesDataStore,
        incidentsRepository: IncidentsRepository
    ) {
        self.preferencesStore = preferencesStore

        incidentsData = incidentsDataSubject

        let incidentDataErase = incidentsData
            .eraseToAnyPublisher()
            .share()

        incident = incidentDataErase
            .map({ data in
                return data.selected
            })
            .share()
        incidentId = incidentDataErase
            .map { data in data.selectedId }
            .share()

        let incidentsPublisher = incidentsRepository.incidents.eraseToAnyPublisher()
        let preferencesPublisher = preferencesStore.preferences.eraseToAnyPublisher()
        Publishers.CombineLatest(
            incidentsPublisher,
            preferencesPublisher
        )
        .filter { incidents, _ in
            incidents.isNotEmpty && self.incidentIdCache == EmptyIncident.id
        }
        .sink { incidents, preferences in
            var targetId = self.incidentIdCache
            if targetId == EmptyIncident.id {
                targetId = preferences.selectedIncidentId
            }

            var targetIncident = incidents.first { $0.id == targetId } ?? EmptyIncident
            if targetIncident.isEmptyIncident {
                targetIncident = incidents[0]
            }

            self.incidentIdCache = targetIncident.id
            self.incidentsDataSubject.value = IncidentsData(
                isLoading: false,
                selected: targetIncident,
                incidents: incidents
            )
        }
        .store(in: &disposables)
    }

    func setIncident(incident: Incident) {
        incidentLock.withLock {
            preferencesStore.setSelectedIncident(incident.id)
            incidentsDataSubject.value = incidentsDataSubject.value.copy {
                $0.selected = incident
            }
        }
    }
}
