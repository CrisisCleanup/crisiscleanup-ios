import GRDB

struct PopulatedSyncStats: Equatable, Decodable, FetchableRecord {
    let worksiteSyncStat: WorksiteSyncStatRecord
    var stats: IncidentDataSyncStats { worksiteSyncStat.asExternalModel() }
    let incidentWorksitesSecondarySyncStat: IncidentWorksitesSecondarySyncStatsRecord?
    var secondaryStats: IncidentDataSyncStats? {
        incidentWorksitesSecondarySyncStat?.asExternalModel()
    }

    var hasSyncedCore: Bool { worksiteSyncStat.successfulSync != nil && worksiteSyncStat.pagedCount >= worksiteSyncStat.targetCount }
}
