import Combine
import Foundation
import GRDB

public class LocationDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func saveLocations(
        _ locationsSource: [Location]
    ) async throws {
        let locations = locationsSource.map { location in
            let coordinateStrings = location.coordinates?.map { String($0) }
            var coordinates = coordinateStrings?.commaJoined ?? ""
            if coordinates.isEmpty {
                if let mc = location.multiCoordinates {
                    let lineCoordinates = mc.map { innerCoordinates in
                        innerCoordinates.map { String($0) }.commaJoined
                    }
                    coordinates = lineCoordinates.joined(separator: "\n")
                }
            }
            return LocationRecord(
                id: location.id,
                shapeType: location.shapeLiteral,
                coordinates: coordinates
            )
        }
        try await database.saveLocations(locations)
    }

    func getLocations(_ ids: [Int64]) -> [Location] {
        try! reader.read { db in fetchLocations(db, ids) }
            .map { $0.asExternalModel() }
    }

    func streamLocations(_ ids: [Int64]) -> AnyPublisher<[Location], Error> {
        ValueObservation
            .tracking({ db in self.fetchLocations(db, ids) })
            .removeDuplicates()
            .map { locations in locations.map { $0.asExternalModel() } }
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    private func fetchLocations(_ db: Database, _ ids: [Int64]) -> [LocationRecord] {
        try! LocationRecord
            .filter(ids: Set(ids))
            .fetchAll(db)
    }
}

extension AppDatabase {
    fileprivate func saveLocations(
        _ locations: [LocationRecord]
    ) async throws {
        try await dbWriter.write { db in
            try locations.forEach { location in
                try location.upsert(db)
            }
        }
    }
}
