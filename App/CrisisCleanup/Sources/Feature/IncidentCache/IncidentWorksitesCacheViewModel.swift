import Combine
import Foundation
import SwiftUI

class IncidentWorksitesCacheViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let incidentCacheRepository: IncidentCacheRepository
    private let locationManager: LocationManager
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    private let isNotProduction: Bool

    init(
        incidentSelector: IncidentSelector,
        incidentCacheRepository: IncidentCacheRepository,
        locationManager: LocationManager,
        syncPuller: SyncPuller,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
    ) {
        self.incidentSelector = incidentSelector
        self.incidentCacheRepository = incidentCacheRepository
        self.locationManager = locationManager
        self.syncPuller = syncPuller
        logger = loggerFactory.getLogger("incident-cache")

        isNotProduction = appEnv.isNotProduction
    }
}
