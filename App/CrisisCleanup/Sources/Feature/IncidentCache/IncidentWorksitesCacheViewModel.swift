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

    @Published private(set) var incident = EmptyIncident

    @Published private(set) var isSyncing = false
    @Published private(set) var syncStage = IncidentCacheStage.inactive
    @Published private(set) var lastSynced: String? = nil

    private let isUserActed = ManagedAtomic(false)

    private let editingPreferencesSubject = CurrentValueSubject<IncidentWorksitesCachePreferences, Never>(InitialIncidentWorksitesCachePreferences)
    @Published private(set) var editingPreferences = InitialIncidentWorksitesCachePreferences

    @Published private var isUserMapActed: Bool = false
    private var hasUserInteracted: Bool {
        isUserActed.load(ordering: .relaxed) || isUserMapActed
    }

    let mapCenterMover: any CircleBoundMapMover
    @Published var mapCoordinates = DefaultCoordinates2d
    @Published var isPinCenterScreen = false

    @Published var showExplainLocationPermission = false

    private let useMyLocationExpirationTime = Date.epochZero

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentCacheRepository: IncidentCacheRepository,
        locationManager: LocationManager,
        syncPuller: SyncPuller,
        loggerFactory: AppLoggerFactory,
    ) {
        self.incidentSelector = incidentSelector
        self.incidentCacheRepository = incidentCacheRepository
        self.locationManager = locationManager
        self.syncPuller = syncPuller
        logger = loggerFactory.getLogger("incident-cache")

        mapCenterMover = AppCircleBoundMapMover(
            locationManager: locationManager,
        )
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeSyncing()
        subscribeCoordinates()
        subscribeCachePreferences()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        incidentSelector.incident.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incident, on: self)
            .store(in: &subscriptions)

        mapCenterMover.isUserActedPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isUserMapActed, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $editingPreferences,
            $isUserMapActed,
        )
        .map { (preferences, isMapMoved) in
            preferences.isBoundedByCoordinates && isMapMoved
        }
        .receive(on: RunLoop.main)
        .sink {
            self.isPinCenterScreen = $0
        }
        .store(in: &subscriptions)
    }

    private func subscribeSyncing() {
        incidentCacheRepository.cacheStage.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.syncStage, on: self)
            .store(in: &subscriptions)

        incidentCacheRepository.isSyncingActiveIncident.eraseToAnyPublisher()
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
    }

    private func subscribeCoordinates() {
        mapCenterMover.subscribeLocationStatus()
            .store(in: &subscriptions)

        mapCenterMover.mapCoordinatesPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.mapCoordinates, on: self)
            .store(in: &subscriptions)

        $mapCoordinates
            .throttle(
                for: .seconds(0.1),
                scheduler: RunLoop.current,
                latest: true
            )
            .receive(on: RunLoop.main)
            .sink { coordinates in
                if self.hasUserInteracted {
                    let preferences = self.editingPreferencesSubject.value
                    self.editingPreferencesSubject.value = preferences.copy { p in
                        p.boundedRegionParameters = p.boundedRegionParameters.copy { brp in
                            brp.regionLatitude = coordinates.latitude
                            brp.regionLongitude = coordinates.longitude
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeCachePreferences() {
        editingPreferencesSubject
            .receive(on: RunLoop.main)
            .assign(to: \.editingPreferences, on: self)
            .store(in: &subscriptions)

        incidentCacheRepository.cachePreferences.eraseToAnyPublisher()
            .sink { preferences in
                if self.editingPreferencesSubject.value == InitialIncidentWorksitesCachePreferences {
                    var preferences = preferences

                    let syncingRegionParameters = preferences.boundedRegionParameters
                    with(syncingRegionParameters) { p in
                        if p.regionLatitude != 0.0 || p.regionLongitude != 0.0 {
                            let initialCoordinates = CLLocationCoordinate2DMake(p.regionLatitude, p.regionLongitude)
                            self.mapCenterMover.updateCoordinates(initialCoordinates)
                        }
                    }

                    if syncingRegionParameters.isRegionMyLocation,
                       !self.locationManager.hasLocationAccess
                    {
                        preferences = preferences.copy { p in
                            p.boundedRegionParameters = syncingRegionParameters.copy { srp in
                                srp.isRegionMyLocation = false
                            }
                        }
                    }

                    // TODO: Atomic compare and set
                    self.editingPreferencesSubject.value = preferences
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
                    self.incidentCacheRepository.updateCachePreferences($0)
                }
            }
            .store(in: &subscriptions)
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
        syncPuller.appPullIncidentData(cancelOngoing: true)
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

    // TODO: Simplify state management
    func boundCachingCases(
        isNearMe: Bool,
        isUserAction: Bool = false
    ) {
        if isUserAction {
            isUserActed.store(true, ordering: .sequentiallyConsistent)
        }

        let hasLocationPermission = isNearMe ? locationManager.hasLocationAccess : nil

        if !isNearMe || hasLocationPermission == true {
            updatePreferences(
                isPaused: false,
                isRegionBounded: true,
                isNearMe: isNearMe
            ) {
                if isNearMe {
                    _ = self.mapCenterMover.useMyLocation()
                }

                self.pullIncidentData()
            }
        } else {
            if isUserAction {
                if !mapCenterMover.useMyLocation() {
                    showExplainLocationPermission = true
                }
            }
        }
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
