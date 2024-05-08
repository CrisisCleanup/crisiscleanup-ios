import Combine
import Foundation

class WorksiteImagesViewModel: ObservableObject {
    private let worksiteImageRepository: WorksiteImageRepository
    private let localImageRepository: LocalImageRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let accountDataRepository: AccountDataRepository
    private let syncPusher: SyncPusher
    private let networkMonitor: NetworkMonitor
    private let translator: KeyTranslator
    private let logger: AppLogger

    private let worksiteId: Int64?
    private let imageUri: String
    let screenTitle: String

    init(
        worksiteImageRepository: WorksiteImageRepository,
        localImageRepository: LocalImageRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        accountDataRepository: AccountDataRepository,
        syncPusher: SyncPusher,
        networkMonitor: NetworkMonitor,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory,
        worksiteId: Int64?,
        imageUri: String,
        screenTitle: String
    ) {
        self.worksiteImageRepository = worksiteImageRepository
        self.localImageRepository = localImageRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.accountDataRepository = accountDataRepository
        self.syncPusher = syncPusher
        self.networkMonitor = networkMonitor
        self.translator = translator
        logger = loggerFactory.getLogger("worksite-images")

        self.worksiteId = worksiteId
        self.imageUri = imageUri
        self.screenTitle = screenTitle
    }
}
