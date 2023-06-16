import Combine
import Foundation

public protocol IncidentSelector {
    var incidentId: Published<Int64>.Publisher { get }
    var incident: Published<Incident>.Publisher { get }

    func setIncident(incident: Incident)
}

class IncidentSelectRepository: IncidentSelector {
    @Published private var incidentsDataStream = LoadingIncidentsData
    lazy private(set) var incidentsData = $incidentsDataStream

    @Published private var incidentStream = EmptyIncident
    lazy private(set) var incident = $incidentStream

    @Published private var incidentIdStream = EmptyIncident.id
    lazy private(set) var incidentId = $incidentIdStream

    private let preferencesStore: AppPreferencesDataStore

    private let incidentLock = NSLock()

    private let disposables = Set<AnyCancellable>()

    init(
        preferencesStore: AppPreferencesDataStore,
        incidentsRepository: IncidentsRepository
    ) {
        self.preferencesStore = preferencesStore

        incidentsData.map { $0.selected }
            .assign(to: &incident )
        incident.map { $0.id }
            .assign(to: &incidentId)

        Publishers.CombineLatest(
            incidentsRepository.incidents,
            preferencesStore.preferences
        )
        .filter { incidents, _ in
            incidents.isNotEmpty
        }
        .map { incidents, preferences in
            var targetId = self.incidentIdStream
            if targetId == EmptyIncident.id {
                targetId = preferences.selectedIncidentId
            }

            var targetIncident = incidents.first { $0.id == targetId } ?? EmptyIncident
            if targetIncident == EmptyIncident && incidents.isNotEmpty {
                targetIncident = incidents[0]
            }

            return IncidentsData(
                isLoading: false,
                selected: targetIncident,
                incidents: incidents
            )
        }
        .assign(to: &incidentsData)
    }

    func setIncident(incident: Incident) {
        incidentLock.withLock {
            preferencesStore.setSelectedIncident(id: incident.id)
            incidentsDataStream = incidentsDataStream.copy {
                $0.selected = incident
            }
        }
    }
}
