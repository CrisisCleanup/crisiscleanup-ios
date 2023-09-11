import Combine
import Foundation

public protocol WorksiteInteractor {
    var caseChangesPublisher: any Publisher<CaseChangeTime, Never> { get }

    func onSelectCase(
        _ incidentId: Int64,
        _ worksiteId: Int64
    )

    func onCaseChanged(
        _ incidentId: Int64,
        _ worksiteId: Int64
    )

    func wasCaseSelected(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        reference: Date
    ) -> Bool
}

extension WorksiteInteractor {
    func wasCaseSelected(
        _ incidentId: Int64,
        _ worksiteId: Int64
    ) -> Bool {
        wasCaseSelected(incidentId, worksiteId, reference: Date.now)
    }
}

class CasesWorksiteInteractor: WorksiteInteractor {
    private var selectedCases = [ExistingWorksiteIdentifier: Date]()

    private let recentlySelectedDuration = 1.hours

    private let caseChangesSubject = CurrentValueSubject<CaseChangeTime, Never>(CaseChangeTime())
    let caseChangesPublisher: any Publisher<CaseChangeTime, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector
    ) {
        caseChangesPublisher = caseChangesSubject

        incidentSelector.incidentId
            .sink { _ in
                self.clearSelection()
            }
            .store(in: &disposables)
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
            let selectedInDuration = selectedTime.distance(to: reference) < recentlySelectedDuration
            print("Worksite \(identifier) was selected \(selectedInDuration)")
            return selectedTime.distance(to: reference) < recentlySelectedDuration
        }
        return false
    }
}

public struct CaseChangeTime: Equatable {
    let caseIdentifier: ExistingWorksiteIdentifier
    let time: Date

    init(
        _ identifier: ExistingWorksiteIdentifier,
        time: Date = Date.now
    ) {
        self.init(identifier.incidentId, identifier.worksiteId, time: time)
    }

    init(
        _ incidentId: Int64 = EmptyIncident.id,
        _ worksiteId: Int64 = EmptyWorksite.id,
        time: Date = Date.now
    ) {
        self.caseIdentifier = ExistingWorksiteIdentifier(incidentId: incidentId, worksiteId: worksiteId)
        self.time = time
    }
}
