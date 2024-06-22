import Combine
import Foundation

class ViewListViewModel: ObservableObject {
    private let listsRepository: ListsRepository
    let phoneNumberParser: PhoneNumberParser
    private let translator: KeyTranslator
    private let logger: AppLogger

    let listId: Int64

    private let viewStateSubject = CurrentValueSubject<ViewListViewState, Never>(ViewListViewState(isLoading: true))
    @Published private(set) var viewState = ViewListViewState(isLoading: true)

    @Published private(set) var screenTitle = ""

    private var isFirstVisible = true

    private var subscriptions = Set<AnyCancellable>()

    init(
        listsRepository: ListsRepository,
        phoneNumberParser: PhoneNumberParser,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory,
        listId: Int64
    ) {
        self.listsRepository = listsRepository
        self.phoneNumberParser = phoneNumberParser
        self.translator = translator
        logger = loggerFactory.getLogger("list")
        self.listId = listId
    }

    func onViewAppear() {
        if isFirstVisible {
            isFirstVisible = false

            Task {
                await listsRepository.refreshList(listId)
            }
        }

        subscribeViewState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        listsRepository.streamList(listId)
            .eraseToAnyPublisher()
            .asyncMap { list in
                if (list.id == EmptyList.id) {
                    let listNotFound = self.translator.t("~~List was not found. It is likely deleted.")
                    return ViewListViewState(errorMessage: listNotFound)
                }

                let lookup = await self.listsRepository.getListObjectData(list)
                var objectIds = list.objectIds
                if list.model == .list {
                    objectIds = objectIds.filter { $0 != list.networkId }
                }
                let objectData = objectIds.map {
                    lookup[$0]
                }
                return ViewListViewState(list: list, objectData: objectData)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.viewState, on: self)
            .store(in: &subscriptions)

        $viewState
            .map {
                if $0.list.id != EmptyList.id,
                   $0.list.name.isNotBlank {
                    return $0.list.name
                }

                return self.translator.t("~~List")
            }
            .receive(on: RunLoop.main)
            .assign(to: \.screenTitle, on: self)
            .store(in: &subscriptions)
    }
}

internal struct ViewListViewState {
    let isLoading: Bool
    let list: CrisisCleanupList
    let objectData: [Any?]
    let errorMessage: String

    init(
        isLoading: Bool = false,
        list: CrisisCleanupList = EmptyList,
        objectData: [Any?] = [],
        errorMessage: String = ""
    ) {
        self.isLoading = isLoading
        self.list = list
        self.objectData = objectData
        self.errorMessage = errorMessage
    }
}
