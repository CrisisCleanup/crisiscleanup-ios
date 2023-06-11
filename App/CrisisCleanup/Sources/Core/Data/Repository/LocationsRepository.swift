import Combine

protocol LocationsRepository {
    func streamLocations(_ ids: [Int64]) -> Published<[Location]>.Publisher
    func getLocations(ids: [Int64]) -> [Location]
}
