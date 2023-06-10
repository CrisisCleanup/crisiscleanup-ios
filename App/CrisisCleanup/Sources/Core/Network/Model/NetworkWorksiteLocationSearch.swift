public struct NetworkWorksiteLocationSearch: Codable, Equatable {
    let incidentId: Int64
    let id: Int64
    let address: String
    let caseNumber: String
    let city: String
    let county: String
    let keyWorkType: NetworkWorkType
    let location: NetworkLocation.LocationPoint
    let name: String
    let postalCode: String?
    let state: String

    enum CodingKeys: String, CodingKey {
        case incidentId = "incident"
        case id
        case address
        case caseNumber = "case_number"
        case city
        case county
        case keyWorkType = "key_work_type"
        case location
        case name
        case postalCode = "postal_code"
        case state
    }
}
