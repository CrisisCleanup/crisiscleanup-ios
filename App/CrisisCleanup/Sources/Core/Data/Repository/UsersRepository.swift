public protocol UsersRepository {
    func getMatchingUsers(
        _ q: String,
        _ organization: Int64,
        limit: Int
    ) async -> [PersonContact]

    func queryUpdateUsers(_ userIds: [Int64]) async
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
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let personContactDao: PersonContactDao
    private let logger: AppLogger

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        personContactDao: PersonContactDao,
        incidentOrganizationDao: IncidentOrganizationDao,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.personContactDao = personContactDao
        self.incidentOrganizationDao = incidentOrganizationDao
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

    func queryUpdateUsers(_ userIds: [Int64]) async {
        do {
            let networkUsers = try await networkDataSource.getUsers(userIds)
            let records = networkUsers.compactMap { $0.asRecords() }

            let organizations = records.map { $0.organization }
            let affiliates = records.map { $0.organizationAffiliates }
            try incidentOrganizationDao.saveMissing(organizations, affiliates)

            let persons = records.map { $0.personContact }
            let personOrganizations = records.map { $0.personToOrganization }
            try personContactDao.savePersons(persons, personOrganizations)
        } catch {
            logger.logError(error)
        }
    }
}
