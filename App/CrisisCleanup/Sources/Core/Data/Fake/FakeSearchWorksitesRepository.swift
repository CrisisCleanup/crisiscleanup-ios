private func fakeSummaryResult(
    _ id: Int64,
    _ networkId: Int64
) -> WorksiteSummary {
    return WorksiteSummary (
        id: id,
        networkId: networkId,
        name: "name-\(id)",
        address: "address-\(id)",
        city: "city-\(id)",
        state: "state\(id)",
        zipCode: "zipCode\(id)",
        county: "county\(id)",
        caseNumber: "caseNumber\(id)",
        workType: WorkType(
            id: 24,
            statusLiteral: WorkTypeStatus.openAssigned.literal,
            workTypeLiteral: WorkTypeType.muckOut.rawValue
        )
    )
}

private let summaryResults = [
    fakeSummaryResult(1, 1),
    fakeSummaryResult(2, 11),
    fakeSummaryResult(3, 21),
    fakeSummaryResult(4, 31),
    fakeSummaryResult(5, 41)
]

class FakeSearchWorksitesRepository: SearchWorksitesRepository {
    func searchWorksites(_ incidentId: Int64, _ q: String) async -> [WorksiteSummary] {
        let resultCount = max(0, 8 - q.trim().count)
        return q.isBlank ? [] : Array(ArraySlice(summaryResults[..<resultCount]))
    }

    func locationSearchWorksites(_ incidentId: Int64, _ q: String) async -> [WorksiteSummary] {
        let resultCount = max(0, 3 - q.trim().count)
        return q.isBlank ? [] : Array(ArraySlice(summaryResults[..<resultCount]))
    }
}
