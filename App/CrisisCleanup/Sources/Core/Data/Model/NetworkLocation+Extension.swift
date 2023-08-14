extension Array where Element == NetworkLocation {
    func asRecordSource() -> [Location] {
        map {
            let multiCoordinates = $0.geom?.condensedCoordinates
            let coordinates = $0.poly?.condensedCoordinates ?? $0.point?.coordinates
            return Location(
                id: $0.id,
                shapeLiteral: $0.shapeType,
                coordinates: multiCoordinates == nil ? coordinates : nil,
                multiCoordinates: multiCoordinates
            )
        }
    }
}
