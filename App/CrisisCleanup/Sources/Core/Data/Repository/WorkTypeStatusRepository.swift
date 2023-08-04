import Combine

public protocol WorkTypeStatusRepository {
    var workTypeStatusOptions: any Publisher<[WorkTypeStatus], Never> { get }
    var workTypeStatusFilterOptions: any Publisher<[WorkTypeStatus], Never> { get }

    func loadStatuses(_ force: Bool) async

    func translateStatus(_ status: String) -> String?

    func translateStatus(_ status: WorkTypeStatus) -> String?
}

extension WorkTypeStatusRepository {
    func loadStatuses() async {
        await loadStatuses(false)
    }
}

class CrisisCleanupWorkTypeStatusRepository: WorkTypeStatusRepository {
    private let workTypeStatusOptionsSubject = CurrentValueSubject<[WorkTypeStatus], Never>([])
    let workTypeStatusOptions: any Publisher<[WorkTypeStatus], Never>

    private let workTypeStatusFilterOptionsSubject = CurrentValueSubject<[WorkTypeStatus], Never>([])
    let workTypeStatusFilterOptions: any Publisher<[WorkTypeStatus], Never>

    private let dataSource: CrisisCleanupNetworkDataSource
    private let workTypeStatusDao: WorkTypeStatusDao
    private let logger: AppLogger

    private var statusLookup = [String: PopulatedWorkTypeStatus]()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        workTypeStatusDao: WorkTypeStatusDao,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.workTypeStatusDao = workTypeStatusDao
        logger = loggerFactory.getLogger("work-type-status")

        workTypeStatusOptions = workTypeStatusOptionsSubject
        workTypeStatusFilterOptions = workTypeStatusFilterOptionsSubject
    }

    func loadStatuses(_ force: Bool) async {
        guard statusLookup.isEmpty else {
            return
        }

        var workTypeStatuses = [PopulatedWorkTypeStatus]()
        do {
            let statuses = try await dataSource.getStatuses()?.results ?? []
            try await workTypeStatusDao.upsert(statuses.map { $0.asRecord() })

            workTypeStatuses = try! workTypeStatusDao.getStatuses()
            statusLookup = workTypeStatuses.associateBy { $0.status }
        } catch {
            logger.logError(error)
        }

        workTypeStatusOptionsSubject.value = statusLookup
            .filter { $0.value.primaryState != "need" }
            .map { statusFromLiteral($0.key) }
        workTypeStatusFilterOptionsSubject.value = workTypeStatuses
            .sorted(by: { a, b in a.name.localizedCompare(b.name) == .orderedAscending })
            .map { statusFromLiteral($0.status) }
    }

    func translateStatus(_ status: String) -> String? {
        statusLookup[status]?.name
    }

    func translateStatus(_ status: WorkTypeStatus) -> String? {
        translateStatus(status.literal)
    }
}
