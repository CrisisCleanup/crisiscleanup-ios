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
