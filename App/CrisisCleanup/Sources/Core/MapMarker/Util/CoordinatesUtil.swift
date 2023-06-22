import CoreLocation
import Foundation

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
    let single = Array(double.joined())
    return single
}

extension Array where Element == LocationLatLng {
    func toIncidentBounds() throws -> IncidentBounds {
        let locations = map {
            let multiBounds = $0.multiCoordinates.map { latLngs in
                latLngs.count < 3 ? nil : latLngs.latLngBounds
            }
            var areas = [Double]()
            for i in multiBounds.indices {
                let latLngBounds = multiBounds[i]
                let area = latLngBounds == nil ? 0.0 : PolyUtil.shoelaceArea($0.multiCoordinates[i])
                areas.append(area)
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
                for i in locationLatLng.boundAreas.indices {
                    let area = locationLatLng.boundAreas[i]
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
            incidentCentroid = centerBounds.center
            if PolyUtil.containsLocation(incidentCentroid, locationPoly) {
                var closestPoint = locationPoly[0]
                var closestDistance = PolyUtil.computeSqrDistanceBetween(incidentCentroid, closestPoint)
                for polyPoint in locationPoly {
                    let distance = PolyUtil.computeSqrDistanceBetween(incidentCentroid, polyPoint)
                    if distance < closestDistance {
                        closestDistance = distance
                        closestPoint = polyPoint
                    }
                }

                try Task.checkCancellation()

                var furthestPoint = closestPoint
                var furthestDistance = closestDistance
                let delta = closestPoint.subtract(incidentCentroid)
                let deltaNorm = delta.normalizeOrSelf()
                if deltaNorm != delta {
                    for polyPoint in locationPoly {
                        let polyDelta = polyPoint.subtract(incidentCentroid)
                        let polyDeltaNorm = polyDelta.normalizeOrSelf()
                        if polyDelta != polyDeltaNorm &&
                            polyDeltaNorm.latitude * deltaNorm.latitude + polyDeltaNorm.longitude * deltaNorm.longitude > 0.9
                         {
                            let distance =
                            PolyUtil.computeSqrDistanceBetween(incidentCentroid, polyPoint)
                            if distance > furthestDistance {
                                furthestDistance = distance
                                furthestPoint = polyPoint
                            }
                        }
                    }

                    try Task.checkCancellation()

                    if furthestDistance > closestDistance {
                        // TODO: Spherical interpolate
                        incidentCentroid = LatLng(
                            (closestPoint.latitude + furthestPoint.latitude) * 0.5,
                            (furthestPoint.longitude + furthestPoint.longitude) * 0.5
                        )
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
        // TODO Write tests
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
    fileprivate func normalizeOrSelf() -> LatLng {
        let sqr = latitude * latitude + longitude * longitude
        if sqr > 0 {
            let nDist = sqrt(sqr)
            return LatLng(latitude / nDist, longitude / nDist)
        }
        return self
    }

    fileprivate func subtract(_ latLng: LatLng) -> LatLng {
        LatLng(
            latitude - latLng.latitude,
            longitude - latLng.longitude
        )
    }
}
