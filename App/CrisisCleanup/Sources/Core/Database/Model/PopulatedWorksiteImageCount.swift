import GRDB

struct PopulatedWorksiteImageCount: Equatable, Decodable, FetchableRecord {
    let worksiteId: Int64
    let count: Int
}
