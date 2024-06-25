import Foundation

public protocol ListsSyncer {
    func sync() async throws
}

class AccountListsSyncer: ListsSyncer {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let listsRepository: ListsRepository
    private let logger: AppLogger

    private let syncGuard = NSLock()
    private var isSyncing = false

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        listsRepository: ListsRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.listsRepository = listsRepository
        logger = loggerFactory.getLogger("lists")
    }

    func sync() async throws {
        syncGuard.withLock {
            if isSyncing {
                return
            }
            isSyncing = true
        }

        var networkCount = 0
        var requestingCount = 0
        var cachedLists = [NetworkList]()
        do {
            defer {
                syncGuard.withLock {
                    isSyncing = false
                }
            }

            while networkCount == 0 || requestingCount < networkCount {
                let result = try await networkDataSource.getLists(limit: 100, offset: requestingCount)
                try result.errors?.tryThrowException()

                if networkCount == 0 {
                    networkCount = result.count!
                }

                if let lists = result.results,
                   lists.isNotEmpty {
                    requestingCount += lists.count
                    cachedLists.append(contentsOf: lists)
                } else {
                    break
                }

                if cachedLists.count > 10000 {
                    logger.logError(GenericError("Ignoring lists beyond \(cachedLists.count)"))
                    break
                }

                try Task.checkCancellation()
            }

            await listsRepository.syncLists(cachedLists)
        } catch {
            if error is CancellationError {
                throw error
            }

            logger.logError(error)
        }
    }
}
