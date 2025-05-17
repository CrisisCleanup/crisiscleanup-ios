import Atomics
import Combine
import CombineExt
import Foundation
import MapKit
import SwiftUI

class IncidentWorksitesCacheViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let incidentCacheRepository: IncidentCacheRepository
    private let locationManager: LocationManager
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    private let isNotProduction: Bool

    @Published private(set) var incident = EmptyIncident

    @Published private(set) var isSyncing = false
    @Published private(set) var syncStage = IncidentCacheStage.start
    @Published private(set) var lastSynced: String? = nil

    private let isUserActed = ManagedAtomic(false)

    private let editingPreferencesSubject = CurrentValueSubject<IncidentWorksitesCachePreferences, Never>(InitialIncidentWorksitesCachePreferences)
    @Published private(set) var editingPreferences = InitialIncidentWorksitesCachePreferences

    private var hasUserInteracted: Bool {
        // TODO: Account for boundedRegionDataEditor
        isUserActed.load(ordering: .relaxed)
    }

    let mapCenterMover: MapCenterMover
    @Published var mapCoordinates = DefaultCoordinates2d

    @Published private(set) var showExplainPermissionLocation = false

    private let epochZero = Date(timeIntervalSince1970: 0)
    private let useMyLocationExpirationTime = Date(timeIntervalSince1970: 0)

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

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

        mapCenterMover = AppMapCenterMover(
            locationManager: locationManager,
        )

        isNotProduction = appEnv.isNotProduction
    }

    func onViewAppear() {
        subscribeSyncing()
        subscribeCachePreferences()
        subscribeBoundedRegion()
        subscribeMyLocation()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeSyncing() {
        incidentCacheRepository.cacheStage.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.syncStage, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            incidentCacheRepository.isSyncingActiveIncident.eraseToAnyPublisher(),
            $syncStage,
        )
        .map { (isSyncingActiveIncident, stage) in
            isSyncingActiveIncident && stage != .end
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isSyncing, on: self)
        .store(in: &subscriptions)

        $incident
            .filter { $0 != EmptyIncident }
            .flatMapLatest {
                self.incidentCacheRepository.streamSyncStats($0.id)
                    .eraseToAnyPublisher()
            }
            .compactMap {
                $0?.lastUpdated?.relativeTime
            }
            .receive(on: RunLoop.main)
            .assign(to: \.lastSynced, on: self)
            .store(in: &subscriptions)

        incidentSelector.incident.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incident, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeCachePreferences() {
        editingPreferencesSubject
            .receive(on: RunLoop.main)
            .assign(to: \.editingPreferences, on: self)
            .store(in: &subscriptions)

        // TODO: Finish when boundedRegionDataEditor is available
        incidentCacheRepository.cachePreferences.eraseToAnyPublisher()
            .sink { preferences in
                // TODO: Atomic compare and set
                if self.editingPreferencesSubject.value == InitialIncidentWorksitesCachePreferences {
                    self.editingPreferencesSubject.value = preferences

                    let syncingRegionParameters = preferences.boundedRegionParameters
                    with(syncingRegionParameters) { p in
                        if p.regionLatitude != 0.0 || p.regionLongitude != 0.0 {
                            self.mapCoordinates = CLLocationCoordinate2DMake(p.regionLatitude, p.regionLongitude)
                        }
                    }

//                    if syncingRegionParameters.isRegionMyLocation,
//                       !locationManager.hasLocationAccess
//                    {
//                        editingPreferencesSubject.compareAndSet(
//                            preferences,
//                            editingPreferencesSubject.value.copy { ep in
//                                ep.boundedRegionParameters = syncingRegionParameters.copy { srp in
//                                    srp.isRegionMyLocation = false
//                                }
//                            }
//                        )
//                    }
                }
            }
            .store(in: &subscriptions)

        $editingPreferences
            .throttle(
                for: .seconds(0.3),
                scheduler: RunLoop.current,
                latest: true
            )
            .sink {
                if self.hasUserInteracted {
                    self.incidentCacheRepository.updateCachePreferenes($0)
                } else {
                    if self.isFirstVisible.exchange(false, ordering: .relaxed) {
                        let brp = $0.boundedRegionParameters
                        let coordinates = CLLocationCoordinate2DMake(brp.regionLatitude, brp.regionLongitude)
                        self.mapCenterMover.setInitialCoordinates(coordinates)
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeMyLocation() {
        locationManager.$locationPermission
            .sink {
                if let status = $0,
                   self.locationManager.isAuthorized(status),
                   self.useMyLocationExpirationTime.distance(to: Date.now) < 0.seconds {
                    self.boundCachingCases(isNearMe: true)
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeBoundedRegion() {
        // TODO: Update preferences with boundedRegionDataEditor.centerCoordinates if hasUserInteracted
    }

    private func updatePreferences(
        isPaused: Bool,
        isRegionBounded: Bool,
        isNearMe: Bool = false,
        onPreferencesSent: @escaping () -> Void = {}
    ) {
        let preferences = editingPreferences

        var boundedRegionParameters = preferences.boundedRegionParameters
        with(boundedRegionParameters) { brp in
            if isRegionBounded,
               brp.regionRadiusMiles <= 0.0 {
                boundedRegionParameters = brp.copy {
                    $0.regionRadiusMiles = BOUNDED_REGION_RADIUS_MILES_DEFAULT
                }
            }
        }
        boundedRegionParameters = boundedRegionParameters.copy {
            $0.isRegionMyLocation = isNearMe
        }

        editingPreferencesSubject.value = preferences.copy {
            $0.isPaused = isPaused
            $0.isRegionBounded = isRegionBounded
            $0.boundedRegionParameters = boundedRegionParameters
        }

        onPreferencesSent()
    }

    private func pullIncidentData() {
        print("Mocking pullIncidentData..., uncomment later")
        //        syncPuller.appPullIncidentData(cancelOngoing: true)
    }

    func resumeCachingCases() {
        isUserActed.store(true, ordering: .sequentiallyConsistent)

        updatePreferences(isPaused: false, isRegionBounded: false)

        pullIncidentData()
    }

    func pauseCachingCases() {
        isUserActed.store(true, ordering: .sequentiallyConsistent)

        updatePreferences(isPaused: true, isRegionBounded: false)

        syncPuller.stopPullWorksites()
    }

    func boundCachingCases(
        isNearMe: Bool,
        isUserAction: Bool = false
    ) {
        if isUserAction {
            isUserActed.store(true, ordering: .sequentiallyConsistent)
        }

//        let permissionStatus = if isNearMe {
//            locationManager.hasLocationAccess
//        } else {
//            nil
//        }
//
//        if isNearMe || locationManager.isAuthorized(permissionStatus) {
//            updatePreferences(
//                isPaused: false,
//                isRegionBounded: true,
//                isNearMe: isNearMe
//            ) {
//                if isNearMe {
//                    boundedRegionDataEditor.useMyLocation()
//                }
//
//                pullIncidentData()
//            }
//        } else {
//            if isUserAction {
//                let now = Date.now
//                // TODO: Finish
//            }
//        }
    }

    func resync() {
        pullIncidentData()
    }

    func resetCaching() {
        do {
            try incidentCacheRepository.resetIncidentSyncStats(incident.id)
        } catch {
            logger.logError(error)
        }
    }

    func setBoundedRegionRadius(_ radius: Double) {
        let preferences = editingPreferencesSubject.value
        editingPreferencesSubject.value = preferences.copy { ep in
            ep.boundedRegionParameters = ep.boundedRegionParameters.copy { brp in
                brp.regionRadiusMiles = radius
            }
        }
    }
}
