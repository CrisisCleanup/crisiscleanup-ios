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
    private let isSelectingResultSubject = CurrentValueSubject<Bool, Never>(false)
    @Published var isLoading = false
    @Published var isSelectingResult = false

    let selectedWorksite: any Publisher<(Int64, Int64), Never>
    private let selectedWorksiteSubject = CurrentValueSubject<(Int64, Int64), Never>((EmptyIncident.id, EmptyWorksite.id))

    @Published var recentWorksites: [CaseSummaryResult] = []

    @Published var searchQuery = ""
    private lazy var searchQueryPublisher = $searchQuery

    @Published var searchResults = CasesSearchResults()

    private let emptyResults = [CaseSummaryResult]()

    private var incidentIdCache: Int64 = EmptyIncident.id

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

        selectedWorksite = selectedWorksiteSubject

        incidentIdPublisher = incidentSelector.incidentId.eraseToAnyPublisher()
    }

    func onViewAppear() {
        searchQuery = ""
        subscribeToLoadingStates()
        subscribeToIncidentData()
        subscribeToRecents()
        subscribeToSearch()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToLoadingStates() {
        let subscription = Publishers.CombineLatest3(
            isInitialLoading,
            isSearching,
            isSelectingResultSubject
        )
            .map { (b0, b1, b2) in b0 || b1 || b2 }
            .eraseToAnyPublisher()
            .assign(to: \.isLoading, on: self)
        subscriptions.insert(subscription)

        let selectingSubscription = isSelectingResultSubject
            .assign(to: \.isSelectingResult, on: self)
        subscriptions.insert(selectingSubscription)
    }

    private func subscribeToIncidentData() {
        let subscription = incidentIdPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.incidentIdCache, on: self)
        subscriptions.insert(subscription)
    }

    private func subscribeToRecents() {
        let subscription = incidentIdPublisher
            .map { incidentId in
                do {
                    if incidentId > 0 {
                        return self.worksitesRepository.streamRecentWorksites(incidentId)
                            .eraseToAnyPublisher()
                            .map { list in
                                list.map { summary in
                                    CaseSummaryResult(
                                        summary,
                                        self.getIcon(summary.workType)
                                    )
                                }
                            }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(self.emptyResults).eraseToAnyPublisher()
                    }
                }
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { recents in
                self.isInitialLoading.value = false

                print("Recent cases \(recents)")
                self.recentWorksites = recents
            })
        subscriptions.insert(subscription)
    }

    private func subscribeToSearch() {
        let searchQueryIntermediate = searchQueryPublisher
            .debounce(
                for: .seconds(0.2),
                scheduler: RunLoop.current
            )
            .map { $0.trim() }
            .removeDuplicates()

        let subscription = Publishers.CombineLatest(
            incidentIdPublisher,
            searchQueryIntermediate
        )
        .asyncThrowsMap { (incidentId, q) in
            if incidentId != EmptyIncident.id {
                if q.count < 3 {
                    return CasesSearchResults(q)
                }

                Task { @MainActor in self.isLoading = true }
                do {
                    defer {
                        Task { @MainActor in self.isLoading = false }
                    }

                    let results = await self.searchWorksitesRepository.searchWorksites(incidentId, q)
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
        }
        .receive(on: RunLoop.main)
        .sink { results in
            print("Search results \(results)")
            self.searchResults = results
        }
        subscriptions.insert(subscription)
    }

    private func getIcon(_ workType: WorkType?) -> UIImage? {
        if let wt = workType {
            return mapCaseIconProvider.getIcon(wt.statusClaim, wt.workType, false)
        }
        return nil
    }

    func onBack() -> Bool {
        if searchQuery.isNotBlank {
            searchQuery = ""
            return false
        }

        return true
    }

    func onSelectWorksite(result: CaseSummaryResult) {
        Task {
            if isSelectingResultSubject.value {
                return
            }
            isSelectingResultSubject.value = true
            do {
                defer {
                    isSelectingResultSubject.value = false
                }

                let incidentId = incidentIdCache
                var worksiteId = result.summary.id
                if worksiteId <= 0 {
                    worksiteId = try worksitesRepository.getLocalId(result.networkWorksiteId)
                }
                selectedWorksiteSubject.value = (incidentId, worksiteId)
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
