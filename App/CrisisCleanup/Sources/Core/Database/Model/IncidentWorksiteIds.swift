import GRDB

// sourcery: copyBuilder
public struct IncidentWorksiteIds: Equatable, Decodable, FetchableRecord  {
    let incidentId: Int64
    let id: Int64
    let networkId: Int64

    // sourcery:begin: skipCopy
    var worksiteId: Int64 { id }
    var networkWorksiteId: Int64 { networkId }
    // sourcery:end
}
