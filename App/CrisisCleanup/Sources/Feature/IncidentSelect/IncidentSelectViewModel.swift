import SwiftUI
import Combine

class IncidentSelectViewModel: ObservableObject {
    let incidentSelector: IncidentSelector
    private let incidentsRepository: IncidentsRepository
    let syncPuller: SyncPuller

    @Published private(set) var isLoadingIncidents = true

    @Published private(set) var incidentsData = LoadingIncidentsData

    @Published private(set) var selectedIncidentId :Int64 = -1
    private var isFocusedOnSelected = false

    private var isOptionsRendered = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentsRepository: IncidentsRepository,
        syncPuller: SyncPuller
    ) {
        self.incidentSelector = incidentSelector
        self.incidentsRepository = incidentsRepository
        self.syncPuller = syncPuller
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeIncidents()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        incidentsRepository.isLoading.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidents, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeIncidents() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)

        $incidentsData
            .map { $0.selectedId }
            .filter{ $0 > 0 }
            .receive(on: RunLoop.main)
            .sink { selectedId in
                self.setSelectedIncident()
            }
            .store(in: &subscriptions)
    }

    private func setSelectedIncident() {
        if isOptionsRendered &&
            incidentsData.selectedId > 0 &&
            !isFocusedOnSelected {
            isFocusedOnSelected = true
            selectedIncidentId = incidentsData.selectedId
        }
    }

    func onOptionsRendered() {
        isOptionsRendered = true
        setSelectedIncident()
    }

    func pullIncidents() async {
        await syncPuller.pullIncidents()
    }

    func refreshIncidents() {
        syncPuller.appPull(true, cancelOngoing: true)
    }
}
