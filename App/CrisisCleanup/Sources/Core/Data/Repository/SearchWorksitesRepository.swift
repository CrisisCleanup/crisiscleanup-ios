public protocol SearchWorksitesRepository {
    func searchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary]

    func locationSearchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary]
}
