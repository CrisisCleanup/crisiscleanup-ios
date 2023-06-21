public struct WorksiteSummary {
    /**
     * Local worksite ID
     *
     * This may be set to 0 if lookup was not performed.
     * Perform lookup of worksite with certainty using [networkId].
     */
    let id: Int64
    let networkId: Int64
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let county: String
    let caseNumber: String
    let workType: WorkType?
}
