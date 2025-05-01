import Combine
import Foundation
import GRDB

public class IncidentDataSyncParameterDao {
    private let database: AppDatabase
    private let reader: DatabaseReader
    private let logger: AppLogger

    init(
        _ database: AppDatabase,
        _ logger: AppLogger
    ) {
        self.database = database
        reader = database.reader
        self.logger = logger
    }

    private func fetchSyncStats(_ db: Database, _ incidentId: Int64) throws -> IncidentDataSyncParameterRecord? {
        try IncidentDataSyncParameterRecord
            .filter(id: incidentId)
            .fetchOne(db)
    }

    func streamWorksiteSyncStats(_ incidentId: Int64) -> AnyPublisher<IncidentDataSyncParameters?, Never> {
        ValueObservation
            .tracking({ db in try self.fetchSyncStats(db, incidentId) })
            .removeDuplicates()
            .map { $0?.asExternalModel(self.logger) }
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    func getSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncParameters? {
        try reader.read { db in
            try fetchSyncStats(db, incidentId)?.asExternalModel(logger)
        }
    }

    func insertSyncStats(_ parameters: IncidentDataSyncParameterRecord) async throws {
        try await database.saveParameters(parameters)
    }

    func updateBoundedParameters(
        _ incidentId: Int64,
        _ boundedRegion: String,
        _ boundedSyncedAt: Date
    ) async throws {
        try await database.updateBoundedParameters(incidentId, boundedRegion, boundedSyncedAt)
    }

    func updateUpdatedBefore(
        _ incidentId: Int64,
        _ updatedBefore: Date
    ) async throws {
        try await database.updateUpdatedBefore(incidentId, updatedBefore)
    }

    func updateAdditionalUpdatedBefore(
        _ incidentId: Int64,
        _ updatedBefore: Date
    ) async throws {
        try await database.updateAdditionalUpdatedBefore(incidentId, updatedBefore)
    }

    func updateUpdatedAfter(
        _ incidentId: Int64,
        _ updatedAfter: Date
    ) async throws {
        try await database.updateUpdatedAfter(incidentId, updatedAfter)
    }

    func updateAdditionalUpdatedAfter(
        _ incidentId: Int64,
        _ updatedAfter: Date
    ) async throws {
        try await database.updateAdditionalUpdatedAfter(incidentId, updatedAfter)
    }

    func deleteSyncParameters(_ incidentId: Int64) throws {
        try database.deleteSyncParameters(incidentId)
    }

    func getSyncStatCount() -> Int {
        try! reader.read(IncidentDataSyncParameterRecord.fetchCount(_:))
    }
}

extension AppDatabase {
    fileprivate func saveParameters(
        _ parameters: IncidentDataSyncParameterRecord,
    ) async throws {
        try await dbWriter.write { db in
            try parameters.upsert(db)
        }
    }

    fileprivate func updateBoundedParameters(
        _ incidentId: Int64,
        _ boundedRegion: String,
        _ boundedSyncedAt: Date,
    ) async throws {
        try await dbWriter.write { db in
            try IncidentDataSyncParameterRecord.updateBoundedParameters(
                db,
                incidentId,
                boundedRegion,
                boundedSyncedAt
            )
        }
    }

    fileprivate func updateUpdatedBefore(
        _ incidentId: Int64,
        _ updatedBefore: Date
    ) async throws {
        try await dbWriter.write { db in
            try IncidentDataSyncParameterRecord.updateUpdatedBefore(
                db,
                incidentId,
                updatedBefore
            )
        }
    }

    fileprivate func updateAdditionalUpdatedBefore(
        _ incidentId: Int64,
        _ updatedBefore: Date
    ) async throws {
        try await dbWriter.write { db in
            try IncidentDataSyncParameterRecord.updateAdditionalUpdatedBefore(
                db,
                incidentId,
                updatedBefore
            )
        }
    }

    fileprivate func updateUpdatedAfter(
        _ incidentId: Int64,
        _ updatedAfter: Date
    ) async throws {
        try await dbWriter.write { db in
            try IncidentDataSyncParameterRecord.updateUpdatedAfter(
                db,
                incidentId,
                updatedAfter
            )
        }
    }

    fileprivate func updateAdditionalUpdatedAfter(
        _ incidentId: Int64,
        _ updatedAfter: Date
    ) async throws {
        try await dbWriter.write { db in
            try IncidentDataSyncParameterRecord.updateAdditionalUpdatedAfter(
                db,
                incidentId,
                updatedAfter
            )
        }
    }

    fileprivate func deleteSyncParameters(
        _ id: Int64
    ) throws {
        try dbWriter.write { db in
            _ = try IncidentDataSyncParameterRecord
                .filter(id: id)
                .deleteAll(db)
        }
    }
}
