import Atomics
import Combine
import Foundation

class ResidentNameSearchManager {
    let searchResults: AnyPublisher<ResidentNameSearchResults, Never>

    private let stopSearchingSubject = CurrentValueSubject<Bool, Never>(false)

    private let ignoreNetworkIdSubject = CurrentValueSubject<Int64, Never>(-1)

    private let steadyStateName: ManagedAtomic<AtomicString>

    private var disposables = Set<AnyCancellable>()

    init (
        incidentId: Int64,
        nameQuery: any Publisher<String, Never>,
        searchWorksitesRepository: SearchWorksitesRepository,
        iconProvider: MapCaseIconProvider,
        querySearchThresholdLength: Int = 3,
        disableNameSearch: Bool = false
    ) {
        stopSearchingSubject.value = disableNameSearch

        let ignoreQuery = ManagedAtomic(AtomicString())
        steadyStateName = ignoreQuery

        let activeQuery = ManagedAtomic(AtomicString())
        let searchQuery = Publishers.CombineLatest(
            nameQuery.eraseToAnyPublisher(),
            stopSearchingSubject
        )
            .filter { (_, stop) in !stop }
            .map { (q, _) in q.trim() }
            .debounce(
                for: .seconds(0.1),
                scheduler: RunLoop.current
            )
            .filter { $0 != ignoreQuery.load(ordering: .sequentiallyConsistent).value }
            .removeDuplicates()

        searchQuery
            .sink { q in
                activeQuery.store(AtomicString(q), ordering: .sequentiallyConsistent)
            }
            .store(in: &disposables)

        let worksitesSearchLatestPublisher = LatestAsyncPublisher<(String, [CaseSummaryResult])>()
        let worksitesSearch = searchQuery
            .filter { $0.count >= querySearchThresholdLength }
            .map { q in
                worksitesSearchLatestPublisher.publisher {
                    let worksitesSearch = await searchWorksitesRepository.locationSearchWorksites(incidentId, q)
                    let worksites = worksitesSearch.map { $0.asCaseLocation(iconProvider) }
                    return (q, worksites)
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()

        searchResults = Publishers.CombineLatest4(
            stopSearchingSubject,
            searchQuery,
            worksitesSearch,
            ignoreNetworkIdSubject
        )
        .map { (stop, q, worksiteResults, ignoreNetworkId) in
            let isValid = !stop && q.isNotBlank && q.contains(worksiteResults.0)
            let worksites = {
                if isValid {
                    if ignoreNetworkId > 0 {
                        return worksiteResults.1.filter { $0.networkWorksiteId != ignoreNetworkId }
                    } else {
                        return worksiteResults.1
                    }
                } else {
                    return []
                }
            }()
            return ResidentNameSearchResults(q, worksites)
        }
        .eraseToAnyPublisher()
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    func stopSearchingWorksites() {
        stopSearchingSubject.value = true
    }

    func updateSteadyStateName(_ name: String) {
        steadyStateName.store(AtomicString(name.trim()), ordering: .sequentiallyConsistent)
    }

    func setIgnoreNetworkId(_ id: Int64) {
        ignoreNetworkIdSubject.value = id
    }
}

struct ResidentNameSearchResults {
    let query: String
    let worksites: [CaseSummaryResult]

    let isEmpty: Bool
    let isNotEmpty: Bool

    init(
        _ query: String = "",
        _ worksites: [CaseSummaryResult] = []
    ) {
        self.query = query
        self.worksites = worksites

        isEmpty = worksites.isEmpty
        isNotEmpty = !isEmpty
    }
}
