import Combine
import Foundation
import GRDB

public class ListDao {
    private let database: AppDatabase
    internal let reader: DatabaseReader

    init(
        _ database: AppDatabase
    ) {
        self.database = database
        reader = database.reader
    }

    func syncUpdateLists(
        _ upsertLists: [ListRecord],
        _ deleteNetworkIds: Set<Int64>
    ) async throws {
        try await database.syncUpdateLists(upsertLists, deleteNetworkIds)
    }

    func syncUpdateList(_ list: ListRecord) async throws {
        try await database.syncUpdateList(list)
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

    func streamListCount() -> any Publisher<Int, Never> {
        ValueObservation
            .tracking(fetchListCount(_:))
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
    }

    private func fetchListCount(_ db: Database) throws -> Int {
        try ListRecord
            .fetchCount(db)
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
}

extension AppDatabase {
    fileprivate func syncUpdateLists(
        _ records: [ListRecord],
        _ deleteNetworkIds: Set<Int64>
    ) async throws {
        return try await dbWriter.write { db in
            for record in records {
                try record.syncUpsert(db)
            }
            try ListRecord.deleteByNetworkIds(db, deleteNetworkIds)
        }
    }

    fileprivate func syncUpdateList(
        _ record: ListRecord
    ) async throws {
        return try await dbWriter.write { db in
            try record.syncUpsert(db)
        }
    }
}
