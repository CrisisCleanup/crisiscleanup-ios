import Combine
import Foundation
import SwiftUI

class ViewCaseViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let logger: AppLogger

    let isValidWorksiteIds: Bool
    let incidentIdIn: Int64
    let worksiteIdIn: Int64

    private var isStale = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        loggerFactory: AppLoggerFactory,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        isValidWorksiteIds = incidentId > 0 && worksiteId > 0

        logger = loggerFactory.getLogger("view-case")
    }

    func onViewAppear() {
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    func onViewPop(incidentId: Int64, worksiteId: Int64) {
        if incidentId == incidentIdIn && worksiteId == worksiteIdIn {
            isStale = true
        }
    }

    func isReusable(
        incidentId: Int64,
        worksiteId: Int64
    ) -> Bool {
        let isValidIds = incidentId > 0 && worksiteId > 0
        if !isValidIds && !isValidWorksiteIds { return true }

        return incidentId == incidentIdIn &&
        worksiteId == worksiteIdIn &&
        !isStale
    }

    private func commitRecentWorksite() {
        if isValidWorksiteIds {
            worksitesRepository.setRecentWorksite(
                incidentId: incidentIdIn,
                worksiteId: worksiteIdIn,
                viewStart: Date()
            )
        }
    }
}
