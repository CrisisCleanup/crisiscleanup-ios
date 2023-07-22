import Combine
import GRDB

public class NetworkFileDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamNetworkImageUrl(_ id: Int64) -> AnyPublisher<String?, Never> {
        ValueObservation
            .tracking({ db in try self.fetchNetworkImageUrl(db, id) })
            .removeDuplicates()
            .publisher(in: reader)
            .assertNoFailure()
            .share()
            .eraseToAnyPublisher()
    }

    private func fetchNetworkImageUrl(_ db: Database, _ id: Int64) throws -> String? {
        try NetworkFileRecord
            .all()
            .selectImageUrl()
            .filter(id: id)
            .asRequest(of: String.self)
            .fetchOne(db)
    }
}
