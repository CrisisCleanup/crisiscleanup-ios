import Combine
import Foundation

class ViewListViewModel: ObservableObject {
    private let listsRepository: ListsRepository
    private let translator: KeyTranslator
    private let logger: AppLogger

    let listId: Int64

    init(
        listsRepository: ListsRepository,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory,
        listId: Int64
    ) {
        self.listsRepository = listsRepository
        self.translator = translator
        logger = loggerFactory.getLogger("list")
        self.listId = listId
    }
}
