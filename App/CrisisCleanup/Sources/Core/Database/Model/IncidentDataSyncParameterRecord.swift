import Foundation
import GRDB

struct IncidentDataSyncParameterRecord: Identifiable, Equatable {
    let id: Int64
    let updatedBefore: Date
    let updatedAfter: Date
    let additionalUpdatedBefore: Date
    let additionalUpdatedAfter: Date
    let boundedRegion: String
    let boundedSyncedAt: Date

    func asExternalModel(_ logger: AppLogger) -> IncidentDataSyncParameters {
        var boundedRegionData: IncidentDataSyncParameters.BoundedRegion? = nil
        if boundedRegion.isNotBlank {
            let jsonDecoder = JsonDecoderFactory().decoder()
            do {
                boundedRegionData = try jsonDecoder.decode(IncidentDataSyncParameters.BoundedRegion.self, from: boundedRegion.data(using: .utf8)!)
            } catch {
                logger.logError(error)
            }
        }

        return IncidentDataSyncParameters(
            incidentId: id,
            syncDataMeasures: IncidentDataSyncParameters.SyncDataMeasure(
                core: IncidentDataSyncParameters.SyncTimeMarker(
                    before: updatedBefore,
                    after: updatedAfter
                ),
                additional: IncidentDataSyncParameters.SyncTimeMarker(
                    before: additionalUpdatedBefore,
                    after: additionalUpdatedAfter
                )
            ),
            boundedRegion: boundedRegionData,
            boundedSyncedAt: boundedSyncedAt
        )
    }
}

extension IncidentDataSyncParameterRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentDataSyncParameter"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             updatedBefore,
             updatedAfter,
             additionalUpdatedBefore,
             additionalUpdatedAfter,
             boundedRegion,
             boundedSyncedAt
    }

    static func updateUpdatedBefore(
        _ db: Database,
        _ id: Int64,
        _ updatedBefore: Date
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE incidentDataSyncParameter
            SET updatedBefore=:updatedBefore
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "updatedBefore": updatedBefore,
            ]
        )
    }

    static func updateUpdatedAfter(
        _ db: Database,
        _ id: Int64,
        _ updatedAfter: Date
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE incidentDataSyncParameter
            SET updatedAfter=:updatedAfter
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "updatedAfter": updatedAfter,
            ]
        )
    }

    static func updateAdditionalUpdatedBefore(
        _ db: Database,
        _ id: Int64,
        _ updatedBefore: Date
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE incidentDataSyncParameter
            SET additionalUpdatedBefore=:updatedBefore
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "updatedBefore": updatedBefore,
            ]
        )
    }

    static func updateAdditionalUpdatedAfter(
        _ db: Database,
        _ id: Int64,
        _ updatedAfter: Date
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE incidentDataSyncParameter
            SET additionalUpdatedAfter=:updatedAfter
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "updatedAfter": updatedAfter,
            ]
        )
    }

    static func updateBoundedParameters(
        _ db: Database,
        _ id: Int64,
        _ boundedRegion: String,
        _ boundedSyncedAt: Date
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE incidentDataSyncParameter
            SET boundedRegion=:boundedRegion,
                boundedSyncedAt=:boundedSyncedAt
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "boundedRegion": boundedRegion,
                "boundedSyncedAt": boundedSyncedAt,
            ]
        )
    }
}
