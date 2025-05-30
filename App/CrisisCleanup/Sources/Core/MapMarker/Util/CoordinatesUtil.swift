import CoreLocation
import Foundation

extension Double {
    fileprivate var inLongitudeRange: Double {
        var value = self
        while value < -180 {
            value += 360
        }
        while value > 180 {
            value -= 360
        }
        return value
    }
}

class CoordinatesUtil {
    static func getMiddleLongitude(_ a: Double, _ b: Double) -> Double {
        let a = a.inLongitudeRange
        let b = b.inLongitudeRange

        let min = min(a, b)
        let max = max(a, b)
        let delta = (max - min)
        let deltaMod360 = delta.remainder(dividingBy: 360)

        if deltaMod360 == 0 {
            return a
        } else if deltaMod360 == 180 || deltaMod360 == -180 {
            return (a + 90).inLongitudeRange
        } else {
            return if delta < 180 {
                (a + b) * 0.5
            } else {
                ((min + 360 - max) * 0.5 + max).inLongitudeRange
            }
        }
    }

    static func getMiddleCoordinate(_ a: LatLng, _ b: LatLng) -> LatLng {
        let latitude = (a.latitude + b.latitude) * 0.5
        let longitude = getMiddleLongitude(a.longitude, b.longitude)
        return LatLng(latitude, longitude)
    }

    static func getMiddleCoordinate(_ a: CLLocation, _ b: CLLocation) -> LatLng {
        let latitude = (a.coordinate.latitude + b.coordinate.latitude) * 0.5
        let longitude = getMiddleLongitude(a.coordinate.longitude, b.coordinate.longitude)
        return LatLng(latitude, longitude)
    }

    static func lerpLatitude(
        _ from: Double,
        _ to: Double,
        _ lerp: Double
    ) -> Double {
        from + (to - from) * lerp
    }

    // TODO: Write tests
    static func lerpLongitude(
        _ from: Double,
        _ to: Double,
        _ lerp: Double,
        _ lerpToWest: Bool
    ) -> Double {
        if lerpToWest {
            if to <= from {
                return from + (to - from) * lerp
            }

            let wrappedTo = to - 360
            let longitude = from + (wrappedTo - from) * lerp
            return longitude < -180 ? longitude + 360 : longitude

        } else {
            if to >= from {
                return from + (to - from) * lerp
            }

            let wrappedTo = to + 360
            let longitude = from + (wrappedTo - from) * lerp
            return longitude > 180 ? longitude - 360 : longitude
        }
    }
}

extension Array where Element == Location {
    internal var toLatLngs: [LocationLatLng] {
        filter { $0.multiCoordinates?.isNotEmpty == true || $0.coordinates?.isNotEmpty == true }
            .map {
                let multiCoordintes = $0.multiCoordinates ?? [$0.coordinates!]
                let multiLatLngs = multiCoordintes.map { coords in
                    var latLngs = [LatLng]()
                    for i in stride(from: 1, to: coords.count, by: 2) {
                        let latLng = LatLng(coords[i], coords[i-1])
                        latLngs.append(latLng)
                    }
                    return latLngs
                }
                return LocationLatLng(
                    id: $0.id,
                    shape: $0.shape,
                    multiCoordinates: multiLatLngs
                )
            }
    }
}

fileprivate func flattenDoubleArray(_ double: [[LatLng]]) -> [LatLng] {
    Array(double.joined())
}

extension Array where Element == LocationLatLng {
    func toIncidentBounds() throws -> IncidentBounds {
        let locations = map {
            let multiCoords = $0.multiCoordinates
            let multiBounds = multiCoords.map { latLngs in
                latLngs.count < 3 ? nil : latLngs.latLngBounds
            }
            let areas = multiBounds.enumerated().map { (i, latLngBounds) in
                latLngBounds == nil ? 0.0 : PolyUtil.sphericalArea(multiCoords[i])
            }
            return LocationBounds(
                locationLatLng: $0,
                multiBounds: multiBounds,
                boundAreas: areas
            )
        }

        try Task.checkCancellation()

        let doubleCoordinates = locations.map { locationBounds in
            let double = locationBounds.multiBounds.filter { $0 != nil }
                .map { [$0!.southWest, $0!.northEast] }
            return flattenDoubleArray(double)
        }
        let incidentLatLngBounds = flattenDoubleArray(doubleCoordinates).latLngBounds

        try Task.checkCancellation()

        let maxAreaLocation = locations.reduce(
            (0, ([LatLng]?)(nil), (LatLngBounds?)(nil))) { accOuter, locationLatLng in
                var maxArea = 0.0
                var latLngs: [LatLng]? = nil
                var bounds: LatLngBounds? = nil
                for (i, area) in locationLatLng.boundAreas.enumerated() {
                    if maxArea < area {
                        maxArea = area
                        latLngs = locationLatLng.locationLatLng.multiCoordinates[i]
                        bounds = locationLatLng.multiBounds[i]
                    }
                }

                return accOuter.0 > maxArea ? accOuter : (maxArea, latLngs, bounds)
            }

        try Task.checkCancellation()

        var incidentCentroid = DefaultCoordinates
        let locationPolyOpt = maxAreaLocation.1
        let centerBoundsOpt = maxAreaLocation.2
        if centerBoundsOpt != nil && locationPolyOpt?.isNotEmpty == true {
            let locationPoly = locationPolyOpt!
            let centerBounds = centerBoundsOpt!
            let centroidLocation = centerBounds.center.clLocation
            if !PolyUtil.containsLocation(incidentCentroid, locationPoly) {
                var closestLocation = locationPoly[0].clLocation
                var closestDistance = closestLocation.distance(from: centroidLocation)
                for polyPoint in locationPoly {
                    let polyLocation = polyPoint.clLocation
                    let distance = polyLocation.distance(from: centroidLocation)
                    if distance < closestDistance {
                        closestDistance = distance
                        closestLocation = polyLocation
                    }
                }

                try Task.checkCancellation()

                var furthestLocation = closestLocation
                var furthestDistance = closestDistance
                let delta = closestLocation.subtract(centroidLocation)
                let deltaNorm = delta.normalizeOrSelf()
                if deltaNorm != delta {
                    for polyPoint in locationPoly {
                        let polyLocation = polyPoint.clLocation
                        let polyDelta = polyLocation.subtract(centroidLocation)
                        let polyDeltaNorm = polyDelta.normalizeOrSelf()
                        if polyDelta != polyDeltaNorm &&
                            polyDeltaNorm.coordinate.latitude * deltaNorm.coordinate.latitude +
                            polyDeltaNorm.coordinate.longitude * deltaNorm.coordinate.longitude > 0.9
                         {
                            let distance = polyLocation.distance(from: centroidLocation)
                            if distance > furthestDistance {
                                furthestDistance = distance
                                furthestLocation = polyLocation
                            }
                        }
                    }

                    try Task.checkCancellation()

                    if furthestDistance > closestDistance {
                        // TODO: Spherical interpolate
                        incidentCentroid = CoordinatesUtil.getMiddleCoordinate(closestLocation, furthestLocation)
                    }
                }
            }
        }

        return IncidentBounds(
            locations: locations,
            bounds: incidentLatLngBounds,
            centroid: incidentCentroid
        )
    }
}

extension Array where Element == LatLng {
    var latLngBounds: LatLngBounds {
        let coordinates = firstOrNil ?? DefaultCoordinates
        return toBounds(LatLngBounds(
            southWest: coordinates,
            northEast: coordinates
        ))
    }

    private func toBounds(
        _ startingBounds: LatLngBounds,
        _ minLatSpan: Double = 0.0001,
        _ minLngSpan: Double = 0.0002
    ) -> LatLngBounds {
        let locationBounds = reduce(LatLngBounds.Builder()) { acc, latLng in
            acc.include(latLng)
            return acc
        }

        var sw = startingBounds.southWest
        var ne = startingBounds.northEast
        let center = startingBounds.center
        if ne.latitude - sw.latitude < minLatSpan {
            let halfSpan = minLatSpan * 0.5
            ne = LatLng(center.latitude + halfSpan, ne.longitude)
            sw = LatLng(center.latitude - halfSpan, sw.longitude)
        }
        // TODO: Write tests
        if sw.longitude + 360 - ne.longitude < minLngSpan {
            let halfSpan = minLngSpan * 0.5
            var eastLng = center.latitude - halfSpan
            if eastLng > 180 {
                eastLng -= 360
            }
            var westLng = center.longitude - halfSpan
            if westLng < -180 {
                westLng += 360
            }
            ne = LatLng(ne.latitude, eastLng)
            sw = LatLng(sw.latitude, westLng)
        }
        locationBounds.include(sw)
        locationBounds.include(ne)

        return locationBounds.build()
    }
}

extension LatLng {
    fileprivate var clLocation : CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension CLLocation {
    fileprivate func subtract(_ latLng: CLLocation) -> CLLocation {
        CLLocation(
            latitude: coordinate.latitude - latLng.coordinate.latitude,
            longitude: coordinate.longitude - latLng.coordinate.longitude
        )
    }

    fileprivate func normalizeOrSelf() -> CLLocation {
        let sqr = coordinate.latitude * coordinate.latitude +
        coordinate.longitude * coordinate.longitude
        if sqr > 0 {
            let nDist = sqrt(sqr)
            return CLLocation(
                latitude: coordinate.latitude / nDist,
                longitude: coordinate.longitude / nDist
            )
        }
        return self
    }
}
