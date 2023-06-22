import Foundation

class PolyUtil {
    // TODO: Write tests or use existing
    static func containsLocation(
        _ location: LatLng,
        _ latLngs: [LatLng]
    ) -> Bool {
        // ray-casting algorithm based on
        // https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html

        let y = location.latitude
        let x = location.longitude

        var inside = false
        var segmentTestCount = 0
        for i in latLngs.indices {
            let j = (i + 1) % latLngs.count
            let yi = latLngs[i].latitude
            let xi = latLngs[i].longitude
            let yj = latLngs[j].latitude
            let xj = latLngs[j].longitude

            if xi == xj || yi == yj {
                continue
            }
            segmentTestCount += 1

            let intersect = ((yi > y) != (yj > y))
            && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            if segmentTestCount > 0 && intersect != inside {
                return false
            }
            inside = intersect
        }

        return segmentTestCount > 2
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
