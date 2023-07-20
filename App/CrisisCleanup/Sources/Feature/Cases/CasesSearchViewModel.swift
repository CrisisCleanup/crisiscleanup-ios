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
    @Published private(set) var isLoading = false
    @Published private(set) var isSelectingResult = false

    @Published private(set) var selectedWorksite = (EmptyIncident.id, EmptyWorksite.id)

    @Published private(set) var recentWorksites: [CaseSummaryResult] = []

    @Published var searchQuery = ""

    @Published private(set) var searchResults = CasesSearchResults()

    private let emptyResults = [CaseSummaryResult]()

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
        subscribeToLoadingStates()
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

    private func subscribeToRecents() {
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

    private func subscribeToSearch() {
        let searchQueryIntermediate = $searchQuery
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
        .assign(to: \.searchResults, on: self)
        subscriptions.insert(subscription)
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
