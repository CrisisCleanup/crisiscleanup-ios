import GRDB

struct PopulatedOrganizationLocationIds: Equatable, Decodable, FetchableRecord {
    let primaryLocation: Int64?
    let secondaryLocation: Int64?
}
