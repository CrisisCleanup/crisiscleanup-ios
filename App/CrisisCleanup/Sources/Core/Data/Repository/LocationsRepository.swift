import Combine

public protocol LocationsRepository {
    func streamLocations(_ ids: [Int64]) -> AnyPublisher<[Location], Error>
    func getLocations(ids: [Int64]) -> [Location]
}

class OfflineFirstLocationsRepository: LocationsRepository {
    private let locationDao: LocationDao

    init(_ locationDao: LocationDao) {
        self.locationDao = locationDao
    }

    func streamLocations(_ ids: [Int64]) -> AnyPublisher<[Location], Error> {
        locationDao.streamLocations(ids)
    }

    func getLocations(ids: [Int64]) -> [Location] {
        locationDao.getLocations(ids)
    }
}
