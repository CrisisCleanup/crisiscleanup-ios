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
    lazy var workTypeStatusOptions = $workTypeStatusOptionsStream

    func loadStatuses(_ force: Bool) async {
        // TODO: Do
    }

    func translateStatus(_ status: String) -> String? {
        // TODO: Do
        return nil
    }

    func translateStatus(_ status: WorkTypeStatus) -> String? {
        // TODO: Do
        return nil
    }
}
