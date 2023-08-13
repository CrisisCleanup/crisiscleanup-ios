import Combine
import LRUCache

public protocol CasesFilterRepository {
    var casesFilters: any Publisher<CasesFilter, Never> { get }
    var filtersCount: any Publisher<Int, Never> { get }

    func changeFilters(_ filters: CasesFilter)
    func updateWorkTypeFilters(_ workTypes: [String])
}

class CrisisCleanupCasesFilterRepository: CasesFilterRepository {
    private let dataSource: CasesFiltersDataSource
    private let accountDataRepository: AccountDataRepository
    private let networkDataSource: CrisisCleanupNetworkDataSource

    private let _isLoading = CurrentValueSubject<Bool, Never>(true)
    let isLoading: any Publisher<Bool, Never>

    private let _casesFilters = CurrentValueSubject<CasesFilter, Never>(CasesFilter())
    let casesFilters: any Publisher<CasesFilter, Never>

    let filtersCount: any Publisher<Int, Never>

    private let queryParamCache = LRUCache<OrgCasesFilter, Dictionary<String, Any>>()

    private var subscriptions = Set<AnyCancellable>()

    init(
        dataSource: CasesFiltersDataSource,
        accountDataRepository: AccountDataRepository,
        networkDataSource: CrisisCleanupNetworkDataSource
    ) {
        self.dataSource = dataSource
        self.accountDataRepository = accountDataRepository
        self.networkDataSource = networkDataSource

        isLoading = _isLoading
        casesFilters = _casesFilters
        filtersCount = casesFilters
            .eraseToAnyPublisher()
            .map { $0.changeCount }
    }

    func changeFilters(_ filters: CasesFilter) {
        // TODO: Is task necessary?
        Task {
            dataSource.updateFilters(filters)
        }
    }

    func updateWorkTypeFilters(_ workTypes: [String]) {
        // TODO Update work types removing non-matching
    }
}

fileprivate struct OrgCasesFilter: Hashable {
    let filters: CasesFilter
    let orgId: Int64
}
