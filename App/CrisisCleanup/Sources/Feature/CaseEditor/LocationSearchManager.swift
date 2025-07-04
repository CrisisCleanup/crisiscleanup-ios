import Atomics
import Combine
import Foundation

internal class LocationSearchManager {
    private let addressSearchRepository: AddressSearchRepository

    let isShortQuery: AnyPublisher<Bool, Never>
    let isSearching: AnyPublisher<Bool, Never>
    let searchResults: AnyPublisher<LocationSearchResults, Never>

    private let isSearchingCoordinateAddress = CurrentValueSubject<Bool, Never>(false)

    private var disposables = Set<AnyCancellable>()

    init(
        incidentId: Int64,
        locationQuery: AnyPublisher<String, Never>,
        worksiteProvider: EditableWorksiteProvider,
        searchWorksitesRepository: SearchWorksitesRepository,
        locationManager: LocationManager,
        addressSearchRepository: AddressSearchRepository,
        iconProvider: MapCaseIconProvider,
        logger: AppLogger,
        querySearchThresholdLength: Int = 3
    ) {
        self.addressSearchRepository = addressSearchRepository

        let isShortQuerySubject = CurrentValueSubject<Bool, Never>(false)
        let isSearchingWorksites = CurrentValueSubject<Bool, Never>(false)
        let isSearchingAddresses = CurrentValueSubject<Bool, Never>(false)

        isShortQuery = isShortQuerySubject
            .removeDuplicates()
            .eraseToAnyPublisher()

        isSearching = Publishers.CombineLatest3(
            isSearchingWorksites,
            isSearchingAddresses,
            isSearchingCoordinateAddress
        )
        .map { (b0, b1, b2) in b0 || b1 || b2 }
        .removeDuplicates()
        .eraseToAnyPublisher()

        let intermediateQuery = locationQuery
            .debounce(for: .seconds(0.1), scheduler: RunLoop.current)
            .map { $0.trim() }
            .removeDuplicates()

        intermediateQuery
            .sink {
                isShortQuerySubject.value = $0.count < querySearchThresholdLength
            }
            .store(in: &disposables)

        let activeQuery = ManagedAtomic(AtomicString())
        intermediateQuery
            .sink {
                activeQuery.store(AtomicString($0), ordering: .sequentiallyConsistent)
            }
            .store(in: &disposables)

        let searchQuery = intermediateQuery
            .filter { $0.count >= querySearchThresholdLength }
            .eraseToAnyPublisher()

        let worksitesSearch = searchQuery
            .mapLatest { q in
                isSearchingWorksites.value = true
                do {
                    defer {
                        if (activeQuery.load(ordering: .sequentiallyConsistent).value == q) {
                            isSearchingWorksites.value = false
                        }
                    }

                    let worksitesSearch = await searchWorksitesRepository.locationSearchWorksites(incidentId, q)

                    try Task.checkCancellation()

                    let worksites = worksitesSearch.map {
                        $0.asCaseLocation(iconProvider)
                    }
                    return (q, worksites)
                } catch {
                    logger.logError(error)
                }

                return (q, [])
            }
            .eraseToAnyPublisher()

        let oneMinute = 1.0 / 60.0
        let addressSearch = searchQuery
            .mapLatest { q in
                isSearchingAddresses.value = true
                do {
                    defer {
                        if (activeQuery.load(ordering: .sequentiallyConsistent).value == q) {
                            isSearchingAddresses.value = false
                        }
                    }

                    let incidentBounds = worksiteProvider.incidentBounds

                    var center: LatLng?
                    if let coordinates = locationManager.getLocation() {
                        let deviceLocation = LatLng(
                            coordinates.coordinate.latitude,
                            coordinates.coordinate.longitude
                        )
                        if incidentBounds.containsLocation(deviceLocation) {
                            center = deviceLocation
                        }
                    }
                    if (center == nil && incidentBounds.centroid != DefaultCoordinates) {
                        center = incidentBounds.centroid
                    }

                    var searchSw: LatLng?
                    var searchNe: LatLng?
                    let boundsSw = incidentBounds.bounds.southWest
                    let boundsNe = incidentBounds.bounds.northEast
                    if (boundsNe.latitude - boundsSw.latitude > oneMinute &&
                        (boundsSw.longitude + 360 - boundsNe.longitude > oneMinute)
                    ) {
                        searchSw = boundsSw
                        searchNe = boundsNe
                    }

                    let addresses = await addressSearchRepository.searchAddresses(
                        q,
                        countryCodes: ["US"],
                        center: center,
                        southwest: searchSw,
                        northeast: searchNe
                    )

                    try Task.checkCancellation()

                    return (q, addresses)
                }
            }
            .eraseToAnyPublisher()

        searchResults = Publishers.CombineLatest3(
            searchQuery,
            worksitesSearch,
            addressSearch
        )
        .map { q, worksiteResults, addressResults in
            let addresses = addressResults.0 == q ? addressResults.1 : []
            let worksites = worksiteResults.0 == q ? worksiteResults.1 : []
            return LocationSearchResults(q, addresses, worksites)
        }
        .eraseToAnyPublisher()
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    func queryAddress(_ coordinates: LatLng) async -> LocationAddress? {
        isSearchingCoordinateAddress.value = true
        do {
            defer { isSearchingCoordinateAddress.value = false }

            return await addressSearchRepository.getAddress(coordinates)
        }
    }
}

struct LocationSearchResults {
    let query: String
    let addresses: [KeySearchAddress]
    let worksites: [CaseSummaryResult]

    let isEmpty: Bool

    init(
        _ query: String = "",
        _ addresses: [KeySearchAddress] = [],
        _ worksites: [CaseSummaryResult] = []
    ) {
        self.query = query
        self.addresses = addresses
        self.worksites = worksites

        isEmpty = addresses.isEmpty && worksites.isEmpty
    }
}
