import Foundation
import GRDB

struct LocationRecord: Identifiable, Equatable {
    let id: Int64
    let shapeType: String
    let coordinates: String

    func asExternalModel() -> Location {
        let sequenceStrings = coordinates.split(separator: "\n")
        var singleCoordinates: [Double]? = nil
        var multiCoordinates: [[Double]]? = nil
        if sequenceStrings.count > 1 {
            multiCoordinates = sequenceStrings.map { ss in String(ss).toDoubleList }
        } else {
            singleCoordinates = coordinates.toDoubleList
        }
        return Location(
            id: id,
            shapeLiteral: shapeType,
            coordinates: singleCoordinates,
            multiCoordinates: multiCoordinates
        )
    }
}

extension String {
    fileprivate var toDoubleList: [Double] {
        return split(separator: ",").compactMap { s in Double(s) }
    }
}

extension LocationRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "location"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             shapeType,
             coordinates
    }
}
