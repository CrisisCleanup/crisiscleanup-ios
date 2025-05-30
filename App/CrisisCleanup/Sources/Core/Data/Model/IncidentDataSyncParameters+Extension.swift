import Foundation

extension IncidentDataSyncParameters {
    func asRecord(_ logger: AppLogger) -> IncidentDataSyncParameterRecord {
        var region = ""
        do {
            if let br = boundedRegion {
                let jsonEncoder = JSONEncoder()
                region = try jsonEncoder.encodeToString(br)
            }
        } catch {
            logger.logError(error)
        }
        return IncidentDataSyncParameterRecord(
            id: incidentId,
            updatedBefore: syncDataMeasures.core.before,
            updatedAfter: syncDataMeasures.core.after,
            additionalUpdatedBefore: syncDataMeasures.additional.before,
            additionalUpdatedAfter: syncDataMeasures.additional.after,
            boundedRegion: region,
            boundedSyncedAt: boundedSyncedAt
        )
    }
}
