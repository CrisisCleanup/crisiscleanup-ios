import Combine
import Foundation

public protocol WorksiteInteractor {
    var caseChangesPublisher: any Publisher<CaseChangeTime, Never> { get }

    func onSelectCase(
        _ incidentId: Int64,
        _ worksiteId: Int64,
    )

    func onCaseChanged(
        _ incidentId: Int64,
        _ worksiteId: Int64,
    )

    func wasCaseSelected(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        reference: Date,
    ) -> Bool

    func onCasesChanged(_ identifiers: [ExistingWorksiteIdentifier])
}

extension WorksiteInteractor {
    func wasCaseSelected(
        _ incidentId: Int64,
        _ worksiteId: Int64,
    ) -> Bool {
        wasCaseSelected(incidentId, worksiteId, reference: Date.now)
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
        time: Date = Date.now,
    ) {
        self.caseIdentifier = ExistingWorksiteIdentifier(incidentId: incidentId, worksiteId: worksiteId)
        self.time = time
    }
}
