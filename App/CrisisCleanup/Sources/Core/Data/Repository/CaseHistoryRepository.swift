import Combine
import Foundation

public protocol CaseHistoryRepository {
    var loadingWorksiteId: any Publisher<Int64, Never> { get }

    func streamEvents(_ worksiteId: Int64) -> any Publisher<[CaseHistoryUserEvents], Never>

    func refreshEvents(_ worksiteId: Int64) async -> Int
}

class OfflineFirstCaseHistoryRepository: CaseHistoryRepository {
    private let caseHistoryDao: CaseHistoryDao
    private let personContactDao: PersonContactDao
    private let worksiteDao: WorksiteDao
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let translator: LanguageTranslationsRepository
    private let logger: AppLogger

    private let refreshingWorksiteEvents = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    private let loadingWorksiteEvents = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    let loadingWorksiteId: any Publisher<Int64, Never>

    private let loadEventsLatestPublisher = LatestAsyncPublisher<[CaseHistoryUserEvents]>()

    init(
        caseHistoryDao: CaseHistoryDao,
        personContactDao: PersonContactDao,
        worksiteDao: WorksiteDao,
        networkDataSource: CrisisCleanupNetworkDataSource,
        incidentOrganizationDao: IncidentOrganizationDao,
        translator: LanguageTranslationsRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.caseHistoryDao = caseHistoryDao
        self.personContactDao = personContactDao
        self.worksiteDao = worksiteDao
        self.networkDataSource = networkDataSource
        self.incidentOrganizationDao = incidentOrganizationDao
        self.translator = translator
        logger = loggerFactory.getLogger("case-history-repository")
        self.loadingWorksiteId = Publishers.CombineLatest(
            refreshingWorksiteEvents,
            loadingWorksiteEvents
        )
        .map { id0, id1 in
            id0 == EmptyWorksite.id ? id1 : id0
        }
    }

    func streamEvents(_ worksiteId: Int64) -> any Publisher<[CaseHistoryUserEvents], Never> { caseHistoryDao.streamEvents(worksiteId)
            .map { events in
                self.loadEventsLatestPublisher.publisher {
                    self.loadingWorksiteEvents.value = worksiteId
                    do {
                        defer { self.loadingWorksiteEvents.value = EmptyWorksite.id }

                        return try await self.loadEvents(events)
                    } catch {
                        self.logger.logError(error)
                    }
                    return []
                }
            }
            .switchToLatest()
    }

    private func loadEvents(
        _ events: [PopulatedCaseHistoryEvent]
    ) async throws -> [CaseHistoryUserEvents] {
        let epoch0 = Date(timeIntervalSince1970: 0)
        var userEventMap = [Int64: [CaseHistoryEvent]]()
        var userNewestCreatedAtMap = [Int64: Date]()
        events.map { $0.asExternalModel(translator) }
            .forEach { event in
                let userId = event.createdBy
                if !userEventMap.keys.contains(userId) {
                    userEventMap[userId] = []
                    userNewestCreatedAtMap[userId] = epoch0
                }
                userEventMap[userId]!.append(event)
                if event.createdAt > userNewestCreatedAtMap[userId]! {
                    userNewestCreatedAtMap[userId] = event.createdAt
                }
            }

        try Task.checkCancellation()

        let userIds = userEventMap.keys
        await queryUpdateUsers(Array(userIds))

        try Task.checkCancellation()

        var sortingData: [(CaseHistoryUserEvents, Date)] = []
        for (userId, userEvents) in userEventMap {
            let contact = personContactDao.getContact(userId)
            let person = contact?.personContact
            let org = contact?.incidentOrganization
            sortingData.append(
                (
                    CaseHistoryUserEvents(
                        userId: userId,
                        userName: "\(person?.firstName ?? "") \(person?.lastName ?? "")".trim(),
                        orgName: org?.name ?? "",
                        userPhone: person?.mobile ?? "",
                        userEmail: person?.email ?? "",
                        events: userEvents
                    ),
                    userNewestCreatedAtMap[userId] ?? epoch0
                )
            )
        }

        return sortingData
            .sorted(by: { a, b in a.1 > b.1 })
            .map { $0.0 }
    }

    private func queryUpdateUsers(_ userIds: [Int64]) async {
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

    func refreshEvents(_ worksiteId: Int64) async -> Int {
        refreshingWorksiteEvents.value = worksiteId
        do {
            defer { refreshingWorksiteEvents.value = EmptyWorksite.id }

            let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
            let entities = try await networkDataSource.getCaseHistory(networkWorksiteId)
                .map { $0.asRecords(worksiteId) }
            let events = entities.map { $0.0 }
            let attrs = entities.map { $0.1 }
            try caseHistoryDao.saveEvents(worksiteId, events, attrs)
            return events.count
        } catch {
            logger.logError(error)
        }
        return 0
    }
}
