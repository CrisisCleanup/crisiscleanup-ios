import Combine

public protocol WorkTypeStatusRepository {
    var workTypeStatusOptions: Published<[WorkTypeStatus]>.Publisher { get }

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
    @Published private var workTypeStatusOptionsStream: [WorkTypeStatus] = []
    lazy private(set) var workTypeStatusOptions = $workTypeStatusOptionsStream

    private let dataSource: CrisisCleanupNetworkDataSource
    private let logger: AppLogger

    private var statusLookup = [String: PopulatedWorkTypeStatus]()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        logger = loggerFactory.getLogger("work-type-status")
    }

    func loadStatuses(_ force: Bool) async {
        if statusLookup.count > 0 { return }

        do {
            let statuses = try await dataSource.getStatuses()?.results ?? []
            statusLookup = statuses.map { $0.asPopulatedModel() }.associateBy { $0.status }
        } catch {
            logger.logError(error)
        }
    }

    func translateStatus(_ status: String) -> String? {
        return statusLookup[status]?.name
    }

    func translateStatus(_ status: WorkTypeStatus) -> String? {
        return translateStatus(status.literal)
    }
}
