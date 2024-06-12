import Combine
import Foundation
import GRDB

public class ListDao {
    private let database: AppDatabase
    internal let reader: DatabaseReader
    private let appLogger: AppLogger

    init(
        _ database: AppDatabase,
        _ appLogger: AppLogger
    ) {
        self.database = database
        reader = database.reader

        self.appLogger = appLogger
    }

    func streamIncidentLists(_ incidentId: Int64) -> AnyPublisher<[PopulatedList], Never> {
        ValueObservation
            .tracking({ db in try self.fetchIncidentLists(db, incidentId) })
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    private func fetchIncidentLists(_ db: Database, _ incidentId: Int64) throws -> [PopulatedList] {
        try ListRecord
            .all()
            .byIncident(incidentId)
            .orderByUpdatedAtDesc()
            .including(optional: ListRecord.incident)
            .asRequest(of: PopulatedList.self)
            .fetchAll(db)
    }

    func streamList(_ id: Int64) -> AnyPublisher<PopulatedList?, Never> {
        ValueObservation
            .tracking({ db in try self.fetchList(db, id) })
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    private func fetchList(_ db: Database, _ id: Int64) throws -> PopulatedList? {
        try ListRecord
            .filter(id: id)
            .including(optional: ListRecord.incident)
            .asRequest(of: PopulatedList.self)
            .fetchOne(db)
    }

    func getList(_ id: Int64) -> ListRecord? {
        try! reader.read { db in
            try ListRecord
                .filter(id: id)
                .including(optional: ListRecord.incident)
                .fetchOne(db)
        }
    }

    func getListsByNetworkIds(_ ids: Set<Int64>) -> [PopulatedList] {
        try! reader.read { db in
            try ListRecord
                .all()
                .filterByNetworkIds(ids)
                .including(optional: ListRecord.incident)
                .asRequest(of: PopulatedList.self)
                .fetchAll(db)
        }
    }

    // TODO: Consider when changes have been made to the table in any way and refresh data
    func pageLists(
        pageSize: Int = 30,
        offset: Int = 0
    ) -> [PopulatedList] {
        try! reader.read { db in
            try ListRecord
                .all()
                .orderByUpdatedAtDesc()
                .limit(pageSize, offset: offset)
                .including(optional: ListRecord.incident)
                .asRequest(of: PopulatedList.self)
                .fetchAll(db)
        }
    }

    func deleteList(_ id: Int64) async throws {
        _ = try await database.dbWriter.write { db in
            try ListRecord.deleteOne(db, id: id)
        }
    }

    func deleteListsByNetworkIds(_ networkIds: Set<Int64>) async throws {
        try await database.dbWriter.write { db in
            try ListRecord.deleteByNetworkIds(db, networkIds)
        }
    }
}
