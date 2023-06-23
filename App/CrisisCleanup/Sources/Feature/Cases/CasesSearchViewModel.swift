import Combine
import SwiftUI

class CasesSearchViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let worksitesRepository: WorksitesRepository
    private let searchWorksitesRepository: SearchWorksitesRepository
    private let mapCaseIconProvider: MapCaseIconProvider
    private let logger: AppLogger

    private let isInitialLoading = CurrentValueSubject<Bool, Never>(false)
    private let isSearching = CurrentValueSubject<Bool, Never>(false)
    private let isSelectingResult = CurrentValueSubject<Bool, Never>(false)
    @Published var isLoading = false

    let selectedWorksite: any Publisher<(Int64, Int64), Never>
    private let selectedWorksiteSubject = CurrentValueSubject<(Int64, Int64), Never>((EmptyIncident.id, EmptyWorksite.id))

    let recentWorksites: any Publisher<[CaseSummaryResult], Never>
    private let recentWorksitesSubject = CurrentValueSubject<[CaseSummaryResult], Never>([])

    @Published var searchQuery = ""
    private lazy var searchQueryPublisher = $searchQuery

    let searchResults: any Publisher<CasesSearchResults, Never>
    private let searchResultsSubject = CurrentValueSubject<CasesSearchResults, Never>(CasesSearchResults())

    private let emptyResults = [CaseSummaryResult]()

    private var incidentIdCache: Int64 = EmptyIncident.id

    private var disposables = Set<AnyCancellable>()

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
        recentWorksites = recentWorksitesSubject
        searchResults = searchResultsSubject

        Publishers.CombineLatest3(
            isInitialLoading,
            isSearching,
            isSelectingResult
        )
        .map { (b0, b1, b2) in
            b0 || b1 || b2
        }
        .eraseToAnyPublisher()
        .assign(to: \.isLoading, on: self)
        .store(in: &disposables)

        let incidentIdPublisher = incidentSelector.incidentId.eraseToAnyPublisher()

        incidentIdPublisher
            .assign(to: \.incidentIdCache, on: self)
            .store(in: &disposables)

        incidentIdPublisher
            .map { incidentId in
                do {
                    defer {
                        self.isInitialLoading.value = false
                    }

                    if (incidentId > 0) {
                        return worksitesRepository.streamRecentWorksites(incidentId)
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
            .sink { recents in
                self.recentWorksitesSubject.value = recents
            }
            .store(in: &disposables)

        let searchQueryIntermediate = searchQueryPublisher
            .debounce(
                for: .seconds(0.2),
                scheduler: RunLoop.current
            )
            .map { $0.trim() }
            .removeDuplicates()

        Publishers.CombineLatest(
            incidentIdPublisher,
            searchQueryIntermediate
        )
        .asyncMap { (incidentId, q) in
            if incidentId != EmptyIncident.id {
                if q.count < 3 {
                    return CasesSearchResults(q)
                }

                Task { @MainActor in self.isLoading = true }
                do {
                    defer {
                        Task { @MainActor in self.isLoading = false }
                    }

                    let results = await searchWorksitesRepository.searchWorksites(incidentId, q)
                    let options = results.map { summary in
                        CaseSummaryResult(
                            summary,
                            self.getIcon(summary.workType)
                        )
                    }
                    return CasesSearchResults(q, false, options)
                }
            }
            return CasesSearchResults(q, false)
        }
        .sink { results in
            self.searchResultsSubject.value = results
        }
        .store(in: &disposables)
    }

    private func getIcon(_ workType: WorkType?) -> UIImage? {
        if let wt = workType {
            return mapCaseIconProvider.getIconBitmap(wt.statusClaim, wt.workType, false)
        }
        return nil
    }

    func onBack() -> Bool {
        if (searchQuery.isNotBlank) {
            searchQuery = ""
            return false
        }

        return true
    }

    func onSelectWorksite(result: CaseSummaryResult) {
        Task {
            if (isSelectingResult.value) {
                return
            }
            isSelectingResult.value = true
            do {
                defer {
                    isSelectingResult.value = false
                }

                let incidentId = incidentIdCache
                var worksiteId = result.summary.id
                if worksiteId <= 0 {
                    worksiteId = try await worksitesRepository.getLocalId(result.networkWorksiteId)
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
