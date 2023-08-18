import Combine
import SwiftUI

class CasesSearchViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let worksitesRepository: WorksitesRepository
    private let searchWorksitesRepository: SearchWorksitesRepository
    private let mapCaseIconProvider: MapCaseIconProvider
    private let logger: AppLogger

    private let incidentIdPublisher: AnyPublisher<Int64, Never>

    private let isInitialLoading = CurrentValueSubject<Bool, Never>(true)
    private let isSearching = CurrentValueSubject<Bool, Never>(false)
    private let isSearchingLocal = CurrentValueSubject<Bool, Never>(false)
    private let isCombiningResults = CurrentValueSubject<Bool, Never>(false)
    private let isSelectingResultSubject = CurrentValueSubject<Bool, Never>(false)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isLoading = false
    @Published private(set) var isSelectingResult = false

    @Published private(set) var selectedWorksite = (EmptyIncident.id, EmptyWorksite.id)

    @Published private(set) var recentWorksites: [CaseSummaryResult] = []

    @Published var searchQuery = ""

    @Published private(set) var searchResults = CasesSearchResults()

    private let emptyResults = [CaseSummaryResult]()

    private let latestSearchResultsPublisher = LatestAsyncThrowsPublisher<CasesSearchResults>()
    private let latestLocalSearchResultsPublisher = LatestAsyncThrowsPublisher<CasesSearchResults>()
    private let latestCombineResultsPublisher = LatestAsyncThrowsPublisher<CasesSearchResults>()

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        worksitesRepository: WorksitesRepository,
        searchWorksitesRepository: SearchWorksitesRepository,
        mapCaseIconProvider: MapCaseIconProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentSelector = incidentSelector
        self.worksitesRepository = worksitesRepository
        self.searchWorksitesRepository = searchWorksitesRepository
        self.mapCaseIconProvider = mapCaseIconProvider
        logger = loggerFactory.getLogger("search-case")

        incidentIdPublisher = incidentSelector.incidentId
            .eraseToAnyPublisher()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeRecents()
        subscribeSearch()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        isLoadingSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        let isSearchingState = Publishers.CombineLatest3(
            isSearching,
            isSearchingLocal,
            isCombiningResults
        )
            .map { (b0, b1, b2) in b0 || b1 || b2 }
            .eraseToAnyPublisher()

        Publishers.CombineLatest3(
            isInitialLoading,
            isSearchingState,
            isSelectingResultSubject
        )
            .map { (b0, b1, b2) in b0 || b1 || b2 }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        isSelectingResultSubject
            .assign(to: \.isSelectingResult, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeRecents() {
        incidentIdPublisher
            .map { incidentId in
                let publisher: AnyPublisher<[CaseSummaryResult], Never>
                if incidentId > 0 {
                    publisher = self.worksitesRepository.streamRecentWorksites(incidentId)
                        .eraseToAnyPublisher()
                        .map { list in
                            return list.map { summary in
                                CaseSummaryResult(
                                    summary,
                                    self.getIcon(summary.workType),
                                    listItemKey: summary.id
                                )
                            }
                        }
                        .eraseToAnyPublisher()
                } else {
                    publisher = Just(self.emptyResults).eraseToAnyPublisher()
                }
                return publisher
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { recents in
                self.isInitialLoading.value = false
                self.recentWorksites = recents
            })
            .store(in: &subscriptions)
    }

    private func subscribeSearch() {
        let searchQueryIntermediate = $searchQuery
            .debounce(
                for: .seconds(0.2),
                scheduler: RunLoop.current
            )
            .map { $0.trim() }
            .removeDuplicates()
            .share()

        let networkSearchResults = Publishers.CombineLatest(
            incidentIdPublisher,
            searchQueryIntermediate
        )
        .map { (incidentId, q) in self.latestSearchResultsPublisher.publisher {
            if incidentId != EmptyIncident.id {
                if q.count < 3 {
                    return CasesSearchResults(q)
                }

                self.isSearching.value = true
                do {
                    defer {
                        self.isSearching.value = false
                    }

                    let results = await self.searchWorksitesRepository.searchWorksites(incidentId, q)

                    try Task.checkCancellation()

                    let options = results.map { summary in
                        CaseSummaryResult(
                            summary,
                            self.getIcon(summary.workType)
                        )
                    }
                    return CasesSearchResults(q, false, options)
                }
            }

            try Task.checkCancellation()

            return CasesSearchResults(q, false)
        }}
        .switchToLatest()

        let localSearchResults = Publishers.CombineLatest(
            incidentIdPublisher,
            searchQueryIntermediate
        )
        .map { (incidentId, q) in self.latestLocalSearchResultsPublisher.publisher {
            if incidentId != EmptyIncident.id {
                if q.count < 3 {
                    return CasesSearchResults(q)
                }

                self.isSearchingLocal.value = true
                do {
                    defer {
                        self.isSearchingLocal.value = false
                    }

                    let results = self.searchWorksitesRepository.getMatchingLocalWorksites(incidentId, q)

                    try Task.checkCancellation()

                    let options = results.map { summary in
                        CaseSummaryResult(
                            summary,
                            self.getIcon(summary.workType),
                            listItemKey: summary.networkId > 0 ? summary.networkId : -summary.id
                        )
                    }
                    return CasesSearchResults(q, false, options)
                }
            }

            try Task.checkCancellation()

            return CasesSearchResults(q, false)
        }}
        .switchToLatest()

        Publishers.CombineLatest3(
            searchQueryIntermediate,
            localSearchResults,
            networkSearchResults
        )
        .filter { incidentQ, localResults, networkResults in
            let q = incidentQ
            return q == localResults.q || q == networkResults.q
        }
        .map { incidentQ, localResults, networkResults in self.latestCombineResultsPublisher.publisher {
            let q = incidentQ
            self.isCombiningResults.value = true
            do {
                defer { self.isCombiningResults.value = false }

                let hasLocalResults = q == localResults.q
                let hasNetworkResults = q == networkResults.q
                let options = {
                    if hasLocalResults && hasNetworkResults {
                        let localResultIdIndex = localResults.options.enumerated()
                            .map { element in (element.offset, element.element) }
                            .associateBy { $0.1.id }

                        var results = localResults.options
                        var combined = [CaseSummaryResult]()
                        networkResults.options.forEach { networkResult in
                            if let matchingLocal = localResultIdIndex[networkResult.id] {
                                results[matchingLocal.0] = matchingLocal.1
                            } else {
                                combined.append(networkResult)
                            }
                        }
                        combined.append(contentsOf: results)

                        return combined
                    }
                    if hasLocalResults {
                        return localResults.options
                    }
                    if hasNetworkResults {
                        return networkResults.options
                    }
                    return [CaseSummaryResult]()
                }()

                return CasesSearchResults(q, false, options)
            }
        }}
        .switchToLatest()
        .receive(on: RunLoop.main)
        .assign(to: \.searchResults, on: self)
        .store(in: &subscriptions)
    }

    private func getIcon(_ workType: WorkType?) -> UIImage? {
        if let wt = workType {
            return mapCaseIconProvider.getIcon(wt.statusClaim, wt.workType, false)
        }
        return nil
    }

    func onSelectWorksite(_ result: CaseSummaryResult) {
        if isSelectingResultSubject.value {
            return
        }
        isSelectingResultSubject.value = true
        Task {
            do {
                defer {
                    Task { @MainActor in isSelectingResultSubject.value = false }
                }

                let incidentId = try await incidentIdPublisher.asyncFirst()
                var worksiteId = result.summary.id
                if worksiteId <= 0 {
                    worksiteId = try worksitesRepository.getLocalId(result.networkWorksiteId)
                }

                let mainWorksiteId = worksiteId
                Task { @MainActor in
                    self.selectedWorksite = (incidentId, mainWorksiteId)
                }
            } catch {
                logger.logError(error)
            }
        }
    }
}

struct CasesSearchResults {
    let q: String
    let isShortQ: Bool
    let options: [CaseSummaryResult]

    init(
        _ q: String = "",
        _ isShortQ: Bool = true,
        _ options: [CaseSummaryResult] = []
    ) {
        self.q = q
        self.isShortQ = isShortQ
        self.options = options
    }
}
