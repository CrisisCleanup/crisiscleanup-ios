import Combine
import Foundation

public protocol CasesFilterRepository {
    var casesFilters: CasesFilter { get }
    var casesFiltersLocation: any Publisher<(CasesFilter, Bool), Never> { get }
    var filtersCount: any Publisher<Int, Never> { get }

    func changeFilters(_ filters: CasesFilter)

    func updateWorkTypeFilters(_ workTypes: [String])
}

class CrisisCleanupCasesFilterRepository: CasesFilterRepository {
    private let dataSource: CasesFiltersDataSource
    private let locationManager: LocationManager
    private let networkDataSource: CrisisCleanupNetworkDataSource

    private(set) var casesFilters = CasesFilter()
    let casesFiltersLocation: any Publisher<(CasesFilter, Bool), Never>

    let filtersCount: any Publisher<Int, Never>

    private var subscriptions = Set<AnyCancellable>()

    init(
        dataSource: CasesFiltersDataSource,
        locationManager: LocationManager,
        networkDataSource: CrisisCleanupNetworkDataSource
    ) {
        self.dataSource = dataSource
        self.locationManager = locationManager
        self.networkDataSource = networkDataSource

        casesFiltersLocation = Publishers.CombineLatest(
            dataSource.filters.eraseToAnyPublisher(),
            locationManager.$locationPermission
        )
        .map { filters, _  in
            (filters, locationManager.hasLocationAccess)
        }

        filtersCount = casesFiltersLocation
            .eraseToAnyPublisher()
            .map { $0.0.changeCount }

        casesFiltersLocation
            .eraseToAnyPublisher()
            .map { $0.0 }
            .receive(on: RunLoop.main)
            .assign(to: \.casesFilters, on: self)
            .store(in: &subscriptions)
    }

    func changeFilters(_ filters: CasesFilter) {
        dataSource.updateFilters(filters)
    }

    func updateWorkTypeFilters(_ workTypes: [String]) {
        // TODO: Update work types removing non-matching
    }
}

fileprivate struct OrgCasesFilter: Hashable {
    let filters: CasesFilter
    let orgId: Int64
}
