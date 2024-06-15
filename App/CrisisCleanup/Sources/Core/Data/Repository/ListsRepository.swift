import Combine
import Foundation

public protocol ListsRepository {
    func streamIncidentLists(_ incidentId: Int64) -> any Publisher<[CrisisCleanupList], Never>

    func streamList(_ listId: Int64) -> any Publisher<CrisisCleanupList, Never>

    func syncLists(_ lists: [NetworkList]) async

    func streamListCount() -> any Publisher<Int, Never>
    func pageLists(pageSize: Int, offset: Int) async -> [CrisisCleanupList]

    func refreshList(_ id: Int64) async

    func getListObjectData(_ list: CrisisCleanupList) async -> [Int64: Any]
}

class CrisisCleanupListsRepository: ListsRepository {
    private let listDao: ListDao
    private let incidentDao: IncidentDao
    private let organizationDao: IncidentOrganizationDao
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let personContactDao: PersonContactDao
    private let usersRepository: UsersRepository
    private let worksiteDao: WorksiteDao
    private let logger: AppLogger

    init(
        listDao: ListDao,
        incidentDao: IncidentDao,
        organizationDao: IncidentOrganizationDao,
        networkDataSource: CrisisCleanupNetworkDataSource,
        personContactDao: PersonContactDao,
        usersRepository: UsersRepository,
        worksiteDao: WorksiteDao,
        loggerFactory: AppLoggerFactory
    ) {
        self.listDao = listDao
        self.incidentDao = incidentDao
        self.organizationDao = organizationDao
        self.networkDataSource = networkDataSource
        self.personContactDao = personContactDao
        self.usersRepository = usersRepository
        self.worksiteDao = worksiteDao
        logger = loggerFactory.getLogger("lists-repository")
    }

    func streamIncidentLists(_ incidentId: Int64) -> any Publisher<[CrisisCleanupList], Never> {
        listDao.streamIncidentLists(incidentId).map { records in
            records.map { $0.asExternalModel() }
        }
    }

    func streamList(_ listId: Int64) -> any Publisher<CrisisCleanupList, Never> {
        listDao.streamList(listId).map { $0?.asExternalModel() ?? EmptyList }
    }

    func syncLists(_ lists: [NetworkList]) async {
        let (validLists, invalidLists) = lists.split {
            $0.invalidateAt == nil
        }

        let listEntities = validLists.map { $0.asRecord() }
        let invalidNetworkIds = Set(invalidLists.map { $0.id })
        do {
            try await listDao.syncUpdateLists(listEntities, invalidNetworkIds)
        } catch {
            logger.logError(error)
        }
    }

    func streamListCount() -> any Publisher<Int, Never> {
        listDao.streamListCount()
    }

    func pageLists(pageSize: Int, offset: Int) async -> [CrisisCleanupList] {
        listDao.pageLists(pageSize: pageSize, offset: offset)
            .map { $0.asExternalModel() }
    }

    func refreshList(_ id: Int64) async {
        if let cachedList = listDao.getList(id),
           cachedList.networkId > 0 {
            // TODO: Skip update where locally modified
            //       How to handle delete where update exists? Should delete for consistency.
            do {
                if let listRecord = try await networkDataSource.getList(cachedList.networkId)?.asRecord() {
                    try await listDao.syncUpdateList(listRecord)
                }
            } catch {
                if let code = (error as? CrisisCleanupNetworkError)?.statusCode {
                    if (code == 404) {
                        do {
                            try await listDao.deleteList(id)
                        } catch {
                            // TODO: How should this be handled?
                            logger.logError(error)
                        }
                        return
                    }
                }
                logger.logError(error)
            }
        }
    }

    func getListObjectData(_ list: CrisisCleanupList) async -> [Int64: Any] {
        let objectIds = list.objectIds

        switch list.model {
        case .incident:
            let incidents = incidentDao.getIncidents(objectIds)
            return incidents.associateBy { $0.id }

        case .list:
            let uniqueIds = Set(objectIds)
            func getListLookup() -> [Int64: CrisisCleanupList] {
                listDao.getListsByNetworkIds(uniqueIds)
                    .map { $0.asExternalModel() }
                    .associateBy { $0.networkId }
            }

            var listLookup = getListLookup()
            if (listLookup.count != objectIds.count) {
                let networkListIds = objectIds.filter { !listLookup.keys.contains($0) }
                    .filter {
                        // Guard against infinite refresh
                        $0 != list.networkId
                    }
                do {
                    let listEntities = await networkDataSource.getLists(networkListIds)
                        .compactMap { $0?.asRecord() }
                    try await listDao.syncUpdateLists(listEntities, Set<Int64>())

                    listLookup = getListLookup()
                } catch {
                    logger.logError(error)
                }
            }
            return listLookup

        case .organization:
            func getOrganizationLookup() -> [Int64: IncidentOrganization] {
                do {
                    return try organizationDao.getOrganizations(objectIds)
                        .map { $0.asExternalModel() }
                        .associateBy { $0.id }
                } catch {
                    logger.logError(error)
                }
                return [:]
            }

            var organizationLookup = getOrganizationLookup()
            if (organizationLookup.count != objectIds.count) {
                let networkOrgIds = objectIds.filter { !organizationLookup.keys.contains($0) }
                do {
                    let organizationEntities = try await networkDataSource.getOrganizations(networkOrgIds)
                        .map { $0.asRecord() }
                    try await organizationDao.saveOrganizations(
                        organizationEntities,
                        // TODO: Save contacts and related data from network data. See IncidentOrganizationsSyncer for reference.
                        []
                    )

                    organizationLookup = getOrganizationLookup()
                } catch {
                    logger.logError(error)
                }
            }
            return organizationLookup

        case .user:
            func getContactLookup() -> [Int64: PersonContact] {
                personContactDao.getContacts(objectIds)
                    .map { $0.personContact.asExternalModel() }
                    .associateBy { $0.id }
            }

            var contactLookup = getContactLookup()
            if (contactLookup.count != objectIds.count) {
                let userIds = objectIds.filter { !contactLookup.keys.contains($0) }
                await usersRepository.queryUpdateUsers(userIds)
                contactLookup = getContactLookup()
            }
            return contactLookup

        case .worksite:
            let uniqueIds = Set(objectIds)
            func getNetworkWorksiteLookup() -> [Int64: Worksite] {
                worksiteDao.getWorksitesByNetworkId(uniqueIds)
                    .map { $0.asExternalModel() }
                    .filter { $0.networkId > 0 }
                    .associateBy { $0.networkId }
            }

            var networkWorksiteLookup = getNetworkWorksiteLookup()
            if (networkWorksiteLookup.count != objectIds.count) {
                // TODO: Validate incident exists locally as well
                let worksiteIds = objectIds.filter { !networkWorksiteLookup.keys.contains($0) }
                do {
                    let syncedAt = Date.now
                    if let networkWorksites = try await networkDataSource.getWorksites(worksiteIds) {
                        let entities = networkWorksites.map { $0.asRecords() }
                        try await worksiteDao.syncWorksites(entities, syncedAt)
                    }

                    networkWorksiteLookup = getNetworkWorksiteLookup()
                } catch {
                    logger.logError(error)
                }
            }
            return networkWorksiteLookup

        default:
            break
        }

        return [:]
    }
}
