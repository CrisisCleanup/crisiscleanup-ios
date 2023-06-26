import Foundation

private let HALF_PI = Double.pi / 2.0
private let TWO_PI = 2 * Double.pi
private let FOUR_PI = 4 * Double.pi

// From https://stackoverflow.com/questions/23457916/how-to-get-latitude-and-longitude-bounds-from-google-maps-x-y-and-zoom-parameter
private func yToLat(_ yNorm: Double) -> Double {
    (2 * atan(exp(TWO_PI * (0.5 - yNorm))) - HALF_PI).degrees
}

struct TileCoordinates {
    let x: Int
    let y: Int
    let zoom: Int

    private let maxIndex: Int
    private let southwest: LatLng
    private let northeast: LatLng
    private let lngRangeInverse: Double

    let querySouthwest: LatLng
    let queryNortheast: LatLng

    init(
        x: Int,
        y: Int,
        zoom: Int
    ) {
        self.x = x
        self.y = y
        self.zoom = zoom

        maxIndex = 1 << zoom
        let maxInverse: Double = 1 / Double(maxIndex)

        let xd = Double(x)
        let yd = Double(y)

        let xWest = xd * maxInverse - 0.5
        let xEast = (xd + 1) * maxInverse - 0.5
        let lngWest = xWest * 360
        let lngEast = xEast * 360
        let lngRange = lngEast - lngWest
        lngRangeInverse = 1.0 / lngRange

        let ySouth = (yd + 1) * maxInverse
        let yNorth = yd * maxInverse

        // TODO Find values relative to dot size at the given zoom
        let padScale = zoom < 8 ? maxInverse * 32 : 1.0
        let padLongitude = padScale * 0.0004
        let padLatitude = padScale * 0.0001

        let latSouth = yToLat(ySouth)
        let latNorth = yToLat(yNorth)
        southwest = LatLng(latSouth, lngWest)
        northeast = LatLng(latNorth, lngEast)

        let querySouth = yToLat(ySouth + padLatitude)
        let queryWest = (xWest - padLongitude) * 360
        querySouthwest = LatLng(querySouth, queryWest)
        let queryNorth = yToLat(yNorth - padLatitude)
        let queryEast = (xEast + padLongitude) * 360
        queryNortheast = LatLng(queryNorth, queryEast)
    }

    /**
     * @return x (normalized longitude),y (normalized latitude) or null if coordinates are out of range
     */
    func fromLatLng(
        _ latitude: Double,
        _ longitude: Double
    ) -> (Double, Double)? {
        if (latitude < querySouthwest.latitude ||
            latitude > queryNortheast.latitude ||
            longitude < querySouthwest.longitude ||
            longitude > queryNortheast.longitude
        ) {
            return nil
        }

        let xNorm = (longitude - southwest.longitude) * lngRangeInverse

        // From https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
        var siny = sin(latitude.radians)
        // Truncating to 0.9999 effectively limits latitude to 89.189. This is
        // about a third of a tile past the edge of the world tile.
        siny = min(max(siny, -0.9999), 0.9999)
        var yNorm = 0.5 - log((1 + siny) / (1 - siny)) / FOUR_PI
        yNorm = (yNorm * Double(maxIndex)).truncatingRemainder(dividingBy: 1)

        if (latitude < southwest.latitude) {
            yNorm += 1
        } else if (latitude > northeast.latitude) {
            yNorm -= 1
        }

        return (xNorm, yNorm)
    }
}
