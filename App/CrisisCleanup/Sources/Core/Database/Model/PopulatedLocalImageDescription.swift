import GRDB

struct PopulatedLocalImageDescription: Equatable, Decodable, FetchableRecord {
    let id: Int64
    let uri: String
    let tag: String
}
