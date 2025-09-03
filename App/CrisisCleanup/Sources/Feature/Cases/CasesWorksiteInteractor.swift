import Combine
import Foundation

class CasesWorksiteInteractor: WorksiteInteractor {
    private var selectedCases = [ExistingWorksiteIdentifier: Date]()

    private let recentlySelectedDuration = 1.hours

    private let caseChangesSubject = CurrentValueSubject<CaseChangeTime, Never>(CaseChangeTime())
    let caseChangesPublisher: any Publisher<CaseChangeTime, Never>

    private var cacheIncidentId = EmptyIncident.id

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector
    ) {
        caseChangesPublisher = caseChangesSubject

        incidentSelector.incidentId
            .sink {
                self.cacheIncidentId = $0
                self.clearSelection()
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func clearSelection() {
        selectedCases.removeAll()
    }

    func onSelectCase(_ incidentId: Int64, _ worksiteId: Int64) {
        let identifier = ExistingWorksiteIdentifier(incidentId: incidentId, worksiteId: worksiteId)
        selectedCases[identifier] = Date.now
        caseChangesSubject.value = CaseChangeTime(identifier)
    }

    func onCaseChanged(_ incidentId: Int64, _ worksiteId: Int64) {
        let identifier = ExistingWorksiteIdentifier(incidentId: incidentId, worksiteId: worksiteId)
        caseChangesSubject.value = CaseChangeTime(identifier)
    }

    func wasCaseSelected(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        reference: Date = Date.now
    ) -> Bool {
        let identifier = ExistingWorksiteIdentifier(incidentId: incidentId, worksiteId: worksiteId)
        if let selectedTime = selectedCases[identifier] {
            return selectedTime.distance(to: reference) < recentlySelectedDuration
        }
        return false
    }

    func onCasesChanged(_ identifiers: [ExistingWorksiteIdentifier]) {
        if let matchingCase = identifiers.first(where: { $0.incidentId == cacheIncidentId }) {
            onCaseChanged(matchingCase.incidentId, matchingCase.worksiteId)
        }
    }
}
