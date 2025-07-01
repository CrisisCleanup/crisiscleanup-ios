import Combine
import CombineExt
import Foundation

public protocol CasesFilterRepository {
    var casesFilters: CasesFilter { get }
    var casesFiltersLocation: any Publisher<(CasesFilter, Bool, Double), Never> { get }
    var filtersCount: any Publisher<Int, Never> { get }

    func changeFilters(_ filters: CasesFilter)

    func updateWorkTypeFilters(_ workTypes: [String])

    func reapplyFilters()
}

class CrisisCleanupCasesFilterRepository: CasesFilterRepository {
    private let dataSource: CasesFiltersDataSource
    private let locationManager: LocationManager
    private let networkDataSource: CrisisCleanupNetworkDataSource

    private let applyFilterTimestampSubject = CurrentValueRelay<Double>(0)

    private(set) var casesFilters = CasesFilter()
    let casesFiltersLocation: any Publisher<(CasesFilter, Bool, Double), Never>

    let filtersCount: any Publisher<Int, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CasesFiltersDataSource,
        locationManager: LocationManager,
        networkDataSource: CrisisCleanupNetworkDataSource
    ) {
        self.dataSource = dataSource
        self.locationManager = locationManager
        self.networkDataSource = networkDataSource

        casesFiltersLocation = Publishers.CombineLatest3(
            dataSource.filters.eraseToAnyPublisher(),
            locationManager.$locationPermission,
            applyFilterTimestampSubject
        )
        .map { filters, _, timestamp  in
            (filters, locationManager.hasLocationAccess, timestamp)
        }

        filtersCount = casesFiltersLocation
            .eraseToAnyPublisher()
            .map { $0.0.changeCount }

        casesFiltersLocation
            .eraseToAnyPublisher()
            .map { $0.0 }
            .receive(on: RunLoop.main)
            .assign(to: \.casesFilters, on: self)
            .store(in: &disposables)

        // TODO: For now update or clear work type filters when incident changes
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    func changeFilters(_ filters: CasesFilter) {
        dataSource.updateFilters(filters)
    }

    func updateWorkTypeFilters(_ workTypes: [String]) {
        // TODO: Update work types removing non-matching
    }

    func reapplyFilters() {
        applyFilterTimestampSubject.accept(Date.now.timeIntervalSince1970)
    }
}

fileprivate struct OrgCasesFilter: Hashable {
    let filters: CasesFilter
    let orgId: Int64
}
