import GRDB

struct PopulatedIdNetworkId: Equatable, Decodable, FetchableRecord  {
    let id: Int64
    let networkId: Int64
}

extension Array where Element == PopulatedIdNetworkId {
    func asLookup() -> [Int64: Int64] {
        associate { ($0.id, $0.networkId) }
    }
}
