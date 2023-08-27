import Foundation

class PolyUtil {
    static func containsLocation(
        _ location: LatLng,
        _ latLngs: [LatLng]
    ) -> Bool {
        inRing(location, latLngs)
    }

    // Translation of https://github.com/omanges/turfpy/blob/master/turfpy/measurement.py
    static func inRing(
        _ location: LatLng,
        _ latLngs: [LatLng],
        ignoreBoundary: Bool = false
    ) -> Bool {
        var isInside = false

        let x = location.longitude
        let y = location.latitude
        var j = latLngs.count - 1
        for i in 0..<latLngs.count {
            let xi = latLngs[i].longitude
            let yi = latLngs[i].latitude
            let xj = latLngs[j].longitude
            let yj = latLngs[j].latitude

            let onBoundary = (y * (xi - xj) + yi * (xj - x) + yj * (x - xi) == 0) &&
                ((xi - x) * (xj - x) <= 0) &&
                ((yi - y) * (yj - y) <= 0)

            if onBoundary {
                return !ignoreBoundary
            }

            let intersect = ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

            if intersect {
                isInside = !isInside
            }

            j = i
        }

        return isInside
    }

    static func shoelaceArea(_ latLngs: [LatLng]) -> Double {
        var sumA = 0.0
        var sumB = 0.0
        for i in latLngs.indices {
            let a = i % latLngs.count
            let b = (i + 1) % latLngs.count
            sumA += latLngs[a].latitude * latLngs[b].longitude
            sumB = latLngs[b].latitude * latLngs[a].longitude
        }
        return abs(sumA - sumB) * 0.5
    }

    // TODO: Compute spherical distance instead
    static func computeSqrDistanceBetween(_ pointA: LatLng, _ pointB: LatLng) -> Double {
        return pow(pointA.latitude - pointB.latitude, 2) + pow(pointA.longitude - pointB.longitude, 2)
    }
}
