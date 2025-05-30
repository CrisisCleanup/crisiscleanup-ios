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

    static func sphericalArea(_ latLngs: [LatLng]) -> Double {
        guard latLngs.count > 2 else { return 0 }

        var area = 0.0

        let radiansScalar = .pi / 180.0
        for i in latLngs.indices {
            let j = (i + 1) % latLngs.count

            let vertexA = latLngs[i]
            let vertexB = latLngs[j]

            let phiA = vertexA.latitude * radiansScalar
            let phiB = vertexB.latitude * radiansScalar
            let lambdaA = vertexA.longitude * radiansScalar
            let lambdaB = vertexB.longitude * radiansScalar

            // Calculate the area contribution of this edge
            area += (lambdaB - lambdaA) * (2 + sin(phiA) + sin(phiB))
        }

        // In meters
        let earthRadius = 6.371e6
        area = abs(area * earthRadius * earthRadius / 2.0)

        return area
    }

    // TODO: Compute spherical distance instead
    static func computeSqrDistanceBetween(_ pointA: LatLng, _ pointB: LatLng) -> Double {
        return pow(pointA.latitude - pointB.latitude, 2) + pow(pointA.longitude - pointB.longitude, 2)
    }
}
