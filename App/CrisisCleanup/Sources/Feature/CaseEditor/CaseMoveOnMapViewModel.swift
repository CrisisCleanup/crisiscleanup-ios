import Atomics
import Combine
import Foundation
import SwiftUI

class CaseMoveOnMapViewModel: ObservableObject {
    private let worksiteProvider: EditableWorksiteProvider
    private let locationManager: LocationManager
    private let incidentBoundsProvider: IncidentBoundsProvider
    private let searchWorksitesRepository: SearchWorksitesRepository
    private let caseIconProvider: MapCaseIconProvider
    private let existingWorksiteSelector: ExistingWorksiteSelector
    private let networkMonitor: NetworkMonitor
    private let translator: KeyAssetTranslator

    private let locationSearchManager: LocationSearchManager

    private let incidentId: Int64

    @Published private(set) var hasInternetConnection = true

    private let locationQuerySubject = CurrentValueSubject<String, Never>("")
    @Published var locationQuery = ""
    @Published var isShortQuery = false
    @Published var isLocationSearching = false
    @Published var searchResults = LocationSearchResults()
    private let isSearchResultSelected = ManagedAtomic(false)

    private let outOfBoundsManager: LocationOutOfBoundsManager

    @Published private(set) var isCheckingOutOfBounds = false
    @Published private(set) var locationOutOfBounds = false

    @Published private(set) var editIncidentWorksite = ExistingWorksiteIdentifierNone
    @Published private(set) var isLocationCommitted = false

    @Published private(set) var closeSearchBarTrigger = false

    // TODO: Is random offet necessary?
    var defaultMapZoom: Double {
        if worksiteProvider.editableWorksite.value.address.isBlank {
            return 7
        }
        return 19
    }

    @Published var mapCoordinates = DefaultCoordinates2d
    @Published var showExplainLocationPermission = false
    private var useMyLocationActionTime = Date.now
    @Published var locationOutOfBoundsMessage = ""

    private var subscriptions = Set<AnyCancellable>()

    init(
        worksiteProvider: EditableWorksiteProvider,
        locationManager: LocationManager,
        incidentBoundsProvider: IncidentBoundsProvider,
        searchWorksitesRepository: SearchWorksitesRepository,
        addressSearchRepository: AddressSearchRepository,
        caseIconProvider: MapCaseIconProvider,
        existingWorksiteSelector: ExistingWorksiteSelector,
        networkMonitor: NetworkMonitor,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteProvider = worksiteProvider
        self.locationManager = locationManager
        self.incidentBoundsProvider = incidentBoundsProvider
        self.searchWorksitesRepository = searchWorksitesRepository
        self.caseIconProvider = caseIconProvider
        self.existingWorksiteSelector = existingWorksiteSelector
        self.networkMonitor = networkMonitor
        self.translator = translator

        let logger = loggerFactory.getLogger("move-on-map")

        let worksite = worksiteProvider.editableWorksite.value
        incidentId = worksite.incidentId

        locationSearchManager = LocationSearchManager(
            incidentId: incidentId,
            locationQuery: locationQuerySubject.eraseToAnyPublisher(),
            worksiteProvider: worksiteProvider,
            searchWorksitesRepository: searchWorksitesRepository,
            locationManager: locationManager,
            addressSearchRepository: addressSearchRepository,
            iconProvider: caseIconProvider,
            logger: logger
        )

        outOfBoundsManager = LocationOutOfBoundsManager(
            worksiteProvider,
            incidentBoundsProvider,
            logger
        )
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeInternetConnection()
        subscribeSearchState()
        subscribeLocationState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        locationSearchManager.isSearching
            .receive(on: RunLoop.main)
            .assign(to: \.isLocationSearching, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeInternetConnection() {
        networkMonitor.isOnline.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.hasInternetConnection, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSearchState() {
        $locationQuery
            .sink { self.locationQuerySubject.value = $0 }
            .store(in: &subscriptions)

        locationSearchManager.isShortQuery
            .receive(on: RunLoop.main)
            .assign(to: \.isShortQuery, on: self)
            .store(in: &subscriptions)

        locationSearchManager.searchResults
            .throttle(
                for: .seconds(0.2),
                scheduler: RunLoop.current,
                latest: true
            )
            .receive(on: RunLoop.main)
            .assign(to: \.searchResults, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLocationState() {
        locationManager.$locationPermission
            .receive(on: RunLoop.main)
            .sink { _ in
                if self.locationManager.hasLocationAccess {
                    if self.useMyLocationActionTime.distance(to: Date.now) < 20.seconds {
                        self.updateCoordinatesToMyLocation()
                    }
                }
            }
            .store(in: &subscriptions)

        $mapCoordinates
            .map {
                self.worksiteProvider.getOutOfBoundsMessage($0, self.translator.t)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.locationOutOfBoundsMessage, on: self)
            .store(in: &subscriptions)
    }

    private func updateCoordinatesToMyLocation() {
        if let location = locationManager.getLocation() {
            mapCoordinates = location.coordinate
        }
    }

    func onExistingWorksiteSelected(_ result: CaseSummaryResult) {
        // TODO: Do
        print("worksite selected \(result)")
    }

    func onGeocodeAddressSelected(_ locationAddress: LocationAddress) -> Bool {
        // TODO: Do
        print("address selected \(locationAddress)")
        return false
    }

    func useMyLocation() {
        useMyLocationActionTime = Date.now
        if locationManager.requestLocationAccess() {
            updateCoordinatesToMyLocation()
        }

        if locationManager.isDeniedLocationAccess {
            showExplainLocationPermission = true
        }
    }

    func onSave() {
        // TODO: Do
    }
}

internal class LocationOutOfBoundsManager {
    private let worksiteProvider: EditableWorksiteProvider
    private let boundsProvider: IncidentBoundsProvider
    private let logger: AppLogger

    let locationOutOfBounds = CurrentValueSubject<LocationOutOfBounds?, Never>(nil)

    let isCheckingOutOfBounds = CurrentValueSubject<Bool, Never>(false)

    var isPendingOutOfBounds: Bool {
        isCheckingOutOfBounds.value || locationOutOfBounds.value != nil
    }

    init(
        _ worksiteProvider: EditableWorksiteProvider,
        _ boundsProvider: IncidentBoundsProvider,
        _ logger: AppLogger
    ) {
        self.worksiteProvider = worksiteProvider
        self.boundsProvider = boundsProvider
        self.logger = logger
    }

    func clearOutOfBounds() {
        locationOutOfBounds.value = nil
    }

    func onLocationOutOfBounds(
        coordinates: LatLng,
        selectedAddress: LocationAddress? = nil
    ) {
        Task {
            let outOfBoundsData = LocationOutOfBounds(
                worksiteProvider.incident,
                coordinates,
                address: selectedAddress
            )

            isCheckingOutOfBounds.value = true
            do {
                defer { isCheckingOutOfBounds.value = false }

                let recentIncident = try boundsProvider.isInRecentIncidentBounds(coordinates)
                locationOutOfBounds.value = recentIncident == nil
                ? outOfBoundsData
                : outOfBoundsData.copy { $0.recentIncident = recentIncident }
            } catch {
                logger.logError(error)
            }
        }
    }
}

// sourcery: copyBuilder
struct LocationOutOfBounds {
    let incident: Incident
    let coordinates: LatLng
    let address: LocationAddress?
    let recentIncident: Incident?

    init(
        _ incident: Incident,
        _ coordinates: LatLng,
        address: LocationAddress? = nil,
        recentIncident: Incident? = nil
    ) {
        self.incident = incident
        self.coordinates = coordinates
        self.address = address
        self.recentIncident = recentIncident
    }
}
