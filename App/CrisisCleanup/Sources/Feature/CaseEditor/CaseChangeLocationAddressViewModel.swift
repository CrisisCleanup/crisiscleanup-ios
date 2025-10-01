import Atomics
import Combine
import CoreLocation
import Foundation
import SwiftUI

class CaseChangeLocationAddressViewModel: ObservableObject {
    private var worksiteProvider: EditableWorksiteProvider
    private let locationManager: LocationManager
    private let incidentBoundsProvider: IncidentBoundsProvider
    private let searchWorksitesRepository: SearchWorksitesRepository
    private let addressSearchRepository: AddressSearchRepository
    private let appPreferences: AppPreferencesDataSource
    private let caseIconProvider: MapCaseIconProvider
    private let existingWorksiteSelector: ExistingWorksiteSelector
    private let networkMonitor: NetworkMonitor
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let locationSearchManager: LocationSearchManager

    private let incidentId: Int64

    @Published private(set) var hasInternetConnection = true

    @Published private(set) var isProcessingAction = false

    private let locationQuerySubject = CurrentValueSubject<String, Never>("")
    @Published var locationQuery = ""
    @Published var isShortQuery = false
    @Published var isLocationSearching = false
    @Published var searchResults = LocationSearchResults()
    private var selectedAddress: LocationAddress?

    @Published var isMapSatelliteView = false

    private let outOfBoundsManager: LocationOutOfBoundsManager

    @Published private(set) var isCheckingOutOfBounds = false
    @Published private(set) var locationOutOfBounds: LocationOutOfBounds?

    private let editIncidentWorksiteSubject = CurrentValueSubject<ExistingWorksiteIdentifier, Never>(ExistingWorksiteIdentifierNone)
    @Published private(set) var editIncidentWorksite = ExistingWorksiteIdentifierNone

    private let isSelectingWorksiteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSelectingWorksite = false

    private let isSelectingAddressSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSelectingAddress = false

    @Published private(set) var isLocationCommitted = false

    @Published var closeSearchBarTrigger = false

    let mapCenterMover: MapCenterMover
    @Published var mapCoordinates = DefaultCoordinates2d
    @Published var isPinCenterScreen = false

    @Published var showExplainLocationPermission = false

    @Published var locationOutOfBoundsMessage = ""

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        worksiteProvider: EditableWorksiteProvider,
        locationManager: LocationManager,
        incidentBoundsProvider: IncidentBoundsProvider,
        searchWorksitesRepository: SearchWorksitesRepository,
        addressSearchRepository: AddressSearchRepository,
        appPreferences: AppPreferencesDataSource,
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
        self.addressSearchRepository = addressSearchRepository
        self.appPreferences = appPreferences
        self.caseIconProvider = caseIconProvider
        self.existingWorksiteSelector = existingWorksiteSelector
        self.networkMonitor = networkMonitor
        self.translator = translator
        let logger = loggerFactory.getLogger("move-on-map")
        self.logger = logger

        mapCenterMover = AppMapCenterMover(locationManager: locationManager)

        let worksite = worksiteProvider.editableWorksite.value
        incidentId = worksite.incidentId

        addressSearchRepository.startSearchSession()
        locationSearchManager = LocationSearchManager(
            incidentId: incidentId,
            locationQuery: locationQuerySubject.eraseToAnyPublisher(),
            worksiteProvider: worksiteProvider,
            searchWorksitesRepository: searchWorksitesRepository,
            locationManager: locationManager,
            addressSearchRepository: addressSearchRepository,
            iconProvider: caseIconProvider,
            logger: logger,
        )

        outOfBoundsManager = LocationOutOfBoundsManager(
            worksiteProvider,
            incidentBoundsProvider,
            logger,
        )
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeInternetConnection()
        subscribeSearchState()
        subscribeMapState()
        subscribeLocationState()
        subscribeOutOfBounds()

        if isFirstVisible.exchange(false, ordering: .relaxed) {
            let latLng = worksiteProvider.editableWorksite.value.coordinates
            mapCenterMover.updateCoordinates(latLng.coordinates)
        }
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        locationSearchManager.isSearching
            .receive(on: RunLoop.main)
            .assign(to: \.isLocationSearching, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest3(
            $isCheckingOutOfBounds,
            $isSelectingWorksite,
            $isSelectingAddress
        )
        .map { b0, b1, b2 in b0 || b1 || b2 }
        .receive(on: RunLoop.main)
        .assign(to: \.isProcessingAction, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeInternetConnection() {
        networkMonitor.isOnline.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.hasInternetConnection, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSearchState() {
        isSelectingWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSelectingWorksite, on: self)
            .store(in: &subscriptions)

        editIncidentWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.editIncidentWorksite, on: self)
            .store(in: &subscriptions)

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

    private func subscribeMapState() {
        Task {
            do {
                let preferences = try await appPreferences.preferences.eraseToAnyPublisher().asyncFirst()
                let isMapSatelliteView = preferences.isMapSatelliteView ?? false
                Task { @MainActor in
                    self.isMapSatelliteView = isMapSatelliteView
                }
            } catch {
                logger.logError(error)
            }
        }

        $isMapSatelliteView
            .removeDuplicates()
            .sink {
                self.appPreferences.setMapSatelliteView($0)
            }
            .store(in: &subscriptions)
    }

    private func subscribeLocationState() {
        mapCenterMover.subscribeLocationStatus()
            .store(in: &subscriptions)

        mapCenterMover.mapCoordinatesPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.mapCoordinates, on: self)
            .store(in: &subscriptions)

        mapCenterMover.isPinCenterScreenPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isPinCenterScreen, on: self)
            .store(in: &subscriptions)

        $mapCoordinates
            .map {
                self.worksiteProvider.getOutOfBoundsMessage($0, self.translator.t)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.locationOutOfBoundsMessage, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeOutOfBounds() {
        outOfBoundsManager.isCheckingOutOfBounds
            .receive(on: RunLoop.main)
            .assign(to: \.isCheckingOutOfBounds, on: self)
            .store(in: &subscriptions)

        outOfBoundsManager.locationOutOfBounds
            .receive(on: RunLoop.main)
            .assign(to: \.locationOutOfBounds, on: self)
            .store(in: &subscriptions)
    }

    func useMyLocation() {
        if !mapCenterMover.useMyLocation() {
            showExplainLocationPermission = true
        }
    }

    func onExistingWorksiteSelected(_ result: CaseSummaryResult) {
        if isSelectingWorksite {
            return
        }

        isSelectingWorksiteSubject.value = true
        Task {
            do {
                defer { isSelectingWorksiteSubject.value = false }

                let existingWorksite = await existingWorksiteSelector.onNetworkWorksiteSelected(networkWorksiteId: result.networkWorksiteId)
                if existingWorksite != ExistingWorksiteIdentifierNone {
                    self.worksiteProvider.reset()
                    editIncidentWorksiteSubject.value = existingWorksite
                }
            }
        }
    }

    private func setSearchedLocationAddress(_ locationAddress: LocationAddress) {
        selectedAddress = locationAddress

        locationQuery = ""
        closeSearchBarTrigger = !closeSearchBarTrigger
    }

    func onSearchAddressSelected(_ searchAddress: KeySearchAddress) {
        if outOfBoundsManager.isPendingOutOfBounds {
            return
        }

        isSelectingAddressSubject.value = true
        Task {
            do {
                defer { isSelectingAddressSubject.value = false }

                if let address = try await addressSearchRepository.getPlaceAddress(searchAddress.key) {
                    Task { @MainActor in
                        let coordinates = address.toLatLng()
                        if isCoordinatesInBounds(coordinates) {
                            setSearchedLocationAddress(address)
                            commitChanges()
                        } else {
                            outOfBoundsManager.onLocationOutOfBounds(coordinates, address)
                        }
                    }
                }
            }
        }
    }

    func onSaveMapMove() {
        let latLng = LatLng(mapCoordinates.latitude, mapCoordinates.longitude)
        if isCoordinatesInBounds(latLng) {
            commitChanges()
        } else {
            outOfBoundsManager.onLocationOutOfBounds(latLng)
        }
    }

    private func isCoordinatesInBounds(_ coordinates: LatLng) -> Bool {
        worksiteProvider.incidentBounds.containsLocation(coordinates)
    }

    func cancelOutOfBounds() {
        outOfBoundsManager.clearOutOfBounds()
    }

    func changeIncidentOutOfBounds(_ locationOutOfBounds: LocationOutOfBounds) {
        if let recentIncident = locationOutOfBounds.recentIncident {
            let worksite: Worksite
            if let address = locationOutOfBounds.address {
                worksite = assumeChanges(address)
            } else {
                worksite = assumeChanges(locationOutOfBounds.coordinates)
            }
            worksiteProvider.setIncidentAddressChanged(recentIncident, worksite)
        }

        outOfBoundsManager.clearOutOfBounds()

        isLocationCommitted = true
    }

    func acceptOutOfBounds(_ locationOutOfBounds: LocationOutOfBounds) {
        if let address = locationOutOfBounds.address {
            setSearchedLocationAddress(address)
            commitChanges()
        } else {
            commitLocationCoordinates(locationOutOfBounds.coordinates)
        }
    }

    func commitLocationCoordinates(_ coordinates: LatLng) {
        mapCenterMover.updateCoordinates(coordinates.coordinates)
        commitChanges()
    }

    private func assumeChanges(_ address: LocationAddress) -> Worksite {
        let worksite = worksiteProvider.editableWorksite.value
        return worksite.copy {
            $0.latitude = address.latitude
            $0.longitude = address.longitude
            $0.address = address.address
            $0.city = address.city
            $0.county = address.county
            $0.postalCode = address.zipCode
            $0.state = address.state
        }
    }

    private func assumeChanges(_ coordinates: CLLocationCoordinate2D) -> Worksite {
        worksiteProvider.copyCoordinates(coordinates)
    }

    private func assumeChanges(_ coordinates: LatLng) -> Worksite {
        let worksite = worksiteProvider.editableWorksite.value
        return worksite.copy {
            $0.latitude = coordinates.latitude
            $0.longitude = coordinates.longitude
        }
    }

    func commitChanges() {
        let worksite: Worksite
        if let address = selectedAddress {
            worksite = assumeChanges(address)
        } else {
            worksite = assumeChanges(mapCoordinates)
        }
        worksiteProvider.setAddressChanged(worksite)

        outOfBoundsManager.clearOutOfBounds()

        isLocationCommitted = true
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
        _ coordinates: LatLng,
        _ selectedAddress: LocationAddress? = nil
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
