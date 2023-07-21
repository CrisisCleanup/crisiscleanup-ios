import Combine
import Foundation
import LRUCache

class QueryIncidentsManager {
    private let incidentsRepository: IncidentsRepository

    let incidentQ = CurrentValueSubject<String, Never>("")

    let isLoading: any Publisher<Bool, Never>

    private(set) var incidentLookup = [Int64: Incident]()

    let incidentResults: any Publisher<(String, [IncidentIdNameType]), Never>

    private var disposables = Set<AnyCancellable>()

    init(
        _ incidentsRepository: IncidentsRepository,
        _ cacheMaxSize: Int = 30
    ) {
        self.incidentsRepository = incidentsRepository

        let resultCache = LRUCache<String, [IncidentIdNameType]>(countLimit: cacheMaxSize)

        let isLoadingAll = CurrentValueSubject<Bool, Never>(true)
        let isQuerying = CurrentValueSubject<Bool, Never>(false)

        isLoading = Publishers.CombineLatest(
            isLoadingAll.eraseToAnyPublisher(),
            isQuerying.eraseToAnyPublisher()
        )
        .map { b0, b1 in b0 || b1 }

        let allIncidents = incidentsRepository.incidents.eraseToAnyPublisher()

        let allIncidentsShort = allIncidents.map {
            $0.map { $0.asIdNameType() }
        }

        let trimQ = incidentQ.map { $0.trim() }

        let matchingIncidents = trimQ
            .removeDuplicates()
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .asyncMap { q in
                let incidents = await q.isEmpty
                ? [IncidentIdNameType]()
                : {
                    if let cached = resultCache.value(forKey: q) {
                        return cached
                    }
                    isQuerying.value = true
                    do {
                        defer { isQuerying.value = false }
                        let results = await incidentsRepository.getMatchingIncidents(q)
                        resultCache.setValue(results, forKey: q)
                        return results
                    }
                }()

                return (q, incidents)
            }

        self.incidentResults = Publishers.CombineLatest3(
            allIncidentsShort.eraseToAnyPublisher(),
            matchingIncidents.eraseToAnyPublisher(),
            trimQ.eraseToAnyPublisher()
        )
        .filter { (all, matching, q) in
            all.isNotEmpty && matching.0 == q
        }
        .map { (all, matching, _) in
            let (q, _) = matching
            return q.isEmpty ? (q, all) : matching
        }

        allIncidents
            .map { $0.associateBy { incident in incident.id } }
            .sink(receiveValue: {
                self.incidentLookup = $0
                isLoadingAll.value = false
            })
            .store(in: &disposables)
    }
}
