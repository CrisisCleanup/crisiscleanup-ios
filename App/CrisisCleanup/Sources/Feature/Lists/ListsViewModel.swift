import Combine
import Foundation

class ListsViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let listDataRefresher: ListDataRefresher
    private let listsRepository: ListsRepository
    private let translator: KeyTranslator
    private let logger: AppLogger

    @Published private(set) var tabTitles: [ListsTab: String] = [
        .incidents: "",
        .all: "",
    ]
    @Published private(set) var currentIncident = EmptyIncident

    @Published private(set) var incidentLists = [CrisisCleanupList]()

    private let isRefreshingDataSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isRefreshingData: Bool = false
    private let isLoadingAdditionalSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isLoadingAdditional = false

    @Published private(set) var allListCount = 0
    private let allListIdsSubject = CurrentValueSubject<[Int64], Never>([])
    @Published private(set) var allListIds = [Int64]()

    @Published private(set) var initialListsTab = ListsTab.incidents

    private let listDataLock = NSLock()
    private var listLookup = [Int64: CrisisCleanupList]()

    private let pageDataCount = 30

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        listDataRefresher: ListDataRefresher,
        listsRepository: ListsRepository,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentSelector = incidentSelector
        self.listDataRefresher = listDataRefresher
        self.listsRepository = listsRepository
        self.translator = translator
        logger = loggerFactory.getLogger("lists")

        refreshLists()
    }

    func onViewAppear() {
        subscribeViewState()
        subscribeIncident()
        subscribeLists()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        Publishers.CombineLatest(
            $incidentLists,
            $allListCount
        )
        .map { (incidents, listCount) in
            (incidents.count, listCount)
        }
        .map { (incidentListCount, listCount) in
            let incidentText = self.translator.t("~~Incident")
            let allText = self.translator.t("~~All")
            let incidentsTitle = incidentListCount == 0 ? incidentText : "\(incidentText) (\(incidentListCount))"
            let allTitle = listCount == 0 ? allText : "\(allText) (\(listCount))"
            return [
                .incidents: incidentsTitle,
                .all: allTitle,
            ]
        }
        .receive(on: RunLoop.main)
        .assign(to: \.tabTitles, on: self)
        .store(in: &subscriptions)

        allListIdsSubject
            .receive(on: RunLoop.main)
            .assign(to: \.allListIds, on: self)
            .store(in: &subscriptions)

        isRefreshingDataSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isRefreshingData, on: self)
            .store(in: &subscriptions)

        isLoadingAdditionalSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingAdditional, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeIncident() {
        incidentSelector.incident
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.currentIncident, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLists() {
        listsRepository.streamListCount()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.allListCount, on: self)
            .store(in: &subscriptions)

        $allListCount
            .sink { count in
                await self.pageNextListData(true)
            }
            .store(in: &subscriptions)

        incidentSelector.incident
            .eraseToAnyPublisher()
            .filter { $0 != EmptyIncident }
            .map { incident in
                self.listsRepository.streamIncidentLists(incident.id)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentLists, on: self)
            .store(in: &subscriptions)
    }

    private func clearListData() {
        listDataLock.withLock {
            listLookup = [:]
        }
    }

    func refreshLists(_ force: Bool = false) {
        if (isRefreshingDataSubject.value) {
            return
        }
        isRefreshingDataSubject.value = true

        Task {
            do {
                defer {
                    isRefreshingDataSubject.value = false
                }

                await listDataRefresher.refreshListData(force: force)

                await pageNextListData(true)
            }

            do {
                let incidentId = try await incidentSelector.incident.eraseToAnyPublisher().asyncFirst().id
                if listsRepository.getIncidentListCount(incidentId) == 0 {
                    Task { @MainActor in
                        initialListsTab = ListsTab.all
                    }
                }
            } catch {}
        }
    }

    func onScrollToLastItem() {
        Task {
            await pageNextListData(false)
        }
    }

    func getListData(_ listId: Int64) -> CrisisCleanupList {
        listDataLock.withLock {
            listLookup[listId] ?? EmptyList
        }
    }

    // TODO: Test paging on many lists
    private func pageNextListData(_ clearData: Bool) async {
        listDataLock.withLock {
            guard allListIdsSubject.value.count < allListCount else {
                return
            }
        }

        guard !isLoadingAdditionalSubject.value else {
            return
        }
        isLoadingAdditionalSubject.value = true

        do {
            defer {
                isLoadingAdditionalSubject.value = false
            }

            let offset = clearData ? 0 : allListIdsSubject.value.count
            let pageData = await listsRepository.pageLists(pageSize: pageDataCount, offset: offset)
            let listIds = pageData.map { $0.id }
            listDataLock.withLock {
                for list in pageData {
                    listLookup[list.id] = list
                }
            }
            if clearData {
                allListIdsSubject.value = listIds
            } else {
                allListIdsSubject.value.append(contentsOf: listIds)
            }
        }
    }
}

enum ListsTab {
    case incidents
    case all
}
