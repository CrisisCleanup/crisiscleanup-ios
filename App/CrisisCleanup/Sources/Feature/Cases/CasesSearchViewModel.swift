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
    private let isSearchingNetwork = CurrentValueSubject<Bool, Never>(false)
    private let isSearchingLocal = CurrentValueSubject<Bool, Never>(false)
    private let isCombiningResults = CurrentValueSubject<Bool, Never>(false)
    private let isSelectingResultSubject = CurrentValueSubject<Bool, Never>(false)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
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

        Publishers.CombineLatest4(
            isInitialLoading,
            $isSearching,
            isCombiningResults,
            isSelectingResultSubject
        )
        .map { (b0, b1, b2, b3) in b0 || b1 || b2 || b3 }
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
        Publishers.CombineLatest(
            isSearchingLocal,
            isSearchingNetwork
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isSearching, on: self)
        .store(in: &subscriptions)

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
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { (incidentId, q) in self.latestSearchResultsPublisher.publisher {
                if incidentId != EmptyIncident.id {
                    if q.count < 3 {
                        return CasesSearchResults(q)
                    }

                    self.isSearchingNetwork.value = true
                    do {
                        defer {
                            self.isSearchingNetwork.value = false
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
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { (incidentId, q) in self.latestLocalSearchResultsPublisher.publisher {
                if incidentId != EmptyIncident.id {
                    if q.count < 2 {
                        return CasesSearchResults(q)
                    }

                    self.isSearchingLocal.value = true
                    do {
                        defer {
                            self.isSearchingLocal.value = false
                        }
                        let results = self.searchWorksitesRepository.getMatchingLocalWorksites(incidentId, q)

                        try Task.checkCancellation()

                        var options = results.map { $0.asCaseSummary(self.getIcon) }

                        var leadingCaseSummary: CaseSummaryResult? = nil
                        if options.isNotEmpty {
                            if let caseNumberMatch = self.searchWorksitesRepository.getWorksiteByCaseNumber(incidentId, q.trim()) {
                                if options.firstOrNil?.summary.id != caseNumberMatch.id {
                                    leadingCaseSummary = caseNumberMatch.asCaseSummary(self.getIcon)
                                }
                            }
                        }
                        if let option = leadingCaseSummary {
                            options = options.filter { $0.summary.id != option.summary.id }
                            options.insert(option, at: 0)
                        }

                        return CasesSearchResults(q, false, options)
                    }
                }

                try Task.checkCancellation()

                return CasesSearchResults(q, false)
            }}
            .switchToLatest()

        Publishers.CombineLatest4(
            searchQueryIntermediate,
            $isSearching,
            localSearchResults,
            networkSearchResults
        )
        .filter { incidentQ, _, localResults, networkResults in
            let q = incidentQ
            return q == localResults.q || q == networkResults.q
        }
        .map { incidentQ, searching, localResults, networkResults in self.latestCombineResultsPublisher.publisher {
            let q = incidentQ
            var isShortQ = false
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

                        let localOptions = localResults.options
                        let qLower = q.trim().lowercased()
                        let firstCaseNumberLower = localOptions.firstOrNil?.summary.caseNumber.lowercased()
                        let hasCaseNumberMatch = qLower == firstCaseNumberLower

                        var combined = [CaseSummaryResult]()
                        var localCombined = Set<Int64>([])
                        networkResults.options.forEach { networkResult in
                            if !hasCaseNumberMatch || networkResult.summary.caseNumber.lowercased() != qLower {
                                if let matchingLocal = localResultIdIndex[networkResult.id] {
                                    combined.append(matchingLocal.1)
                                    localCombined.insert(matchingLocal.1.summary.id)
                                } else {
                                    combined.append(networkResult)
                                }
                            }
                        }

                        let caseNumberMatch = hasCaseNumberMatch ? localOptions[0] : nil
                        let ignoreLocalId = caseNumberMatch?.summary.id
                        let localNotCombined = localOptions.filter {
                            $0.summary.id != ignoreLocalId &&
                            !localCombined.contains($0.summary.id)
                        }
                        combined.append(contentsOf: localNotCombined)

                        if let match = caseNumberMatch {
                            combined.insert(match, at: 0)
                        }

                        isShortQ = localResults.isShortQ && networkResults.isShortQ
                        return combined
                    }
                    if hasLocalResults {
                        isShortQ = localResults.isShortQ
                        return localResults.options
                    }
                    if hasNetworkResults {
                        isShortQ = networkResults.isShortQ
                        return networkResults.options
                    }
                    return [CaseSummaryResult]()
                }()

                return CasesSearchResults(q, isShortQ && !searching, options)
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

extension WorksiteSummary {
    fileprivate func asCaseSummary(_ getIcon: (_ workType: WorkType?) -> UIImage?) -> CaseSummaryResult {
        CaseSummaryResult(
            self,
            getIcon(workType),
            listItemKey: networkId > 0 ? networkId : -id
        )
    }
}
