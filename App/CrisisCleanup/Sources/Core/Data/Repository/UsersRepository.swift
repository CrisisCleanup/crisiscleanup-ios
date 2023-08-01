public protocol UsersRepository {
    func getMatchingUsers(
        _ q: String,
        _ organization: Int64,
        limit: Int
    ) async -> [PersonContact]
}

extension UsersRepository {
    func getMatchingUsers(
        _ q: String,
        _ organization: Int64
    ) async -> [PersonContact] {
        await getMatchingUsers(q, organization, limit: 10)
    }
}

class OfflineFirstUsersRepository: UsersRepository {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let logger: AppLogger

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        logger = loggerFactory.getLogger("users-repository")
    }

    func getMatchingUsers(
        _ q: String,
        _ organization: Int64,
        limit: Int
    ) async -> [PersonContact] {
        do {
            return try await networkDataSource.searchUsers(q, organization, limit: limit)
                .map { $0.asExternalModel() }
        } catch {
            logger.logError(error)
        }
        return []
    }
}
