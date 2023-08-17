import Foundation

class CasesMapMarkerManager {
    private let worksitesRepository: WorksitesRepository
    private let locationManager: LocationManager

    init(
        worksitesRepository: WorksitesRepository,
        locationManager: LocationManager
    ) {
        self.worksitesRepository = worksitesRepository
        self.locationManager = locationManager
    }

    private func getWorksitesCount(
        _ id: Int64,
        _ southWest: LatLng,
        _ northEast: LatLng
    ) throws -> Int {
        try worksitesRepository.getWorksitesCount(
            incidentId: id,
            latitudeSouth: southWest.latitude,
            latitudeNorth: northEast.latitude,
            longitudeLeft: southWest.longitude,
            longitudeRight: northEast.longitude
        )
    }

    private func getBoundQueryParams(
        _ maxMarkersOnMap: Int,
        _ incidentId: Int64,
        _ boundsSw: LatLng,
        _ boundsNe: LatLng,
        _ middle: LatLng
    ) throws -> BoundsQueryParams {
        var sw = boundsSw
        var ne = boundsNe
        let fullCount = try getWorksitesCount(incidentId, sw, ne)
        var queryCount = fullCount
        if fullCount > maxMarkersOnMap {
            let halfSw = CoordinatesUtil.getMiddleCoordinate(sw, middle)
            let halfNe = CoordinatesUtil.getMiddleCoordinate(middle, ne)
            let halfCount = try getWorksitesCount(incidentId, halfSw, halfNe)
            if maxMarkersOnMap > halfCount {
                let evenDistWeight =
                Double(maxMarkersOnMap - halfCount) / Double(fullCount - halfCount)
                let south = CoordinatesUtil.lerpLatitude(halfSw.latitude, sw.latitude, evenDistWeight)
                let north = CoordinatesUtil.lerpLatitude(halfNe.latitude, ne.latitude, evenDistWeight)
                let west = CoordinatesUtil.lerpLongitude(halfSw.longitude, sw.longitude, evenDistWeight, true)
                let east = CoordinatesUtil.lerpLongitude(halfNe.longitude, ne.longitude, evenDistWeight, false)
                sw = LatLng(south, west)
                ne = LatLng(north, east)
                // TODO How to best determine count?
            } else {
                sw = halfSw
                ne = halfNe
                queryCount = halfCount
            }
        }

        return BoundsQueryParams(
            fullCount: fullCount,
            queryCount: queryCount,
            southWest: sw,
            northEast: ne
        )
    }

    func queryWorksitesInBounds(
        _ incidentId: Int64,
        _ boundsSw: LatLng,
        _ boundsNe: LatLng
    ) async throws -> ([WorksiteMapMark], Int) {
        // TODO: Adjust based on device resources and app performance
        let maxMarkersOnMap = 1024
        let middle = CoordinatesUtil.getMiddleCoordinate(boundsSw, boundsNe)
        let q = try getBoundQueryParams(
            maxMarkersOnMap,
            incidentId,
            boundsSw,
            boundsNe,
            middle
        )

        try Task.checkCancellation()

        let sw = q.southWest
        let ne = q.northEast
        let mapMarks = try await worksitesRepository.getWorksitesMapVisual(
            incidentId: incidentId,
            latitudeSouth: sw.latitude,
            latitudeNorth: ne.latitude,
            longitudeWest: sw.longitude,
            longitudeEast: ne.longitude,
            // TODO: Review if this is sufficient and mostly complete
            limit: min(q.queryCount, 2 * maxMarkersOnMap),
            offset: 0,
            coordinates: locationManager.getLocation()
        )

        try Task.checkCancellation()

        let mLatRad = middle.latitude.radians
        let mLngRad = middle.longitude.radians
        let midR = sin(mLatRad)
        let midX = midR * cos(mLngRad)
        let midY = midR * sin(mLngRad)
        let midZ = cos(mLatRad)
        func approxDistanceFromMiddle(_ latitude: Double, _ longitude: Double) -> Double {
            let latRad = latitude.radians
            let lngRad = longitude.radians
            let r = sin(latRad)
            let x = r * cos(lngRad)
            let y = r * sin(lngRad)
            let z = cos(latRad)
            return pow(x - midX, 2.0) + pow(y - midY, 2.0) + pow(z - midZ, 2.0)
        }

        let marksFromCenter = mapMarks.enumerated().map { (index, mark) in
            let distanceMeasure = approxDistanceFromMiddle(mark.latitude, mark.longitude)
            return MarkerFromCenter(
                sortOrder: index,
                mark: mark,
                deltaLatitude: mark.latitude - middle.latitude,
                deltaLongitude: mark.longitude - middle.longitude,
                distanceMeasure: distanceMeasure
            )
        }
        let distanceToMiddleSorted = marksFromCenter.sorted(by: { a, b in
            a.distanceMeasure - b.distanceMeasure <= 0
        })

        let endIndex = min(distanceToMiddleSorted.count, maxMarkersOnMap)
        let marks = Array(distanceToMiddleSorted[..<endIndex])
            .sorted(by: { a, b in a.sortOrder <= b.sortOrder })
            .map { $0.mark }

        try Task.checkCancellation()

        return (marks, q.fullCount)
    }
}

private struct BoundsQueryParams {
    let fullCount: Int
    let queryCount: Int
    let southWest: LatLng
    let northEast: LatLng
}

private struct MarkerFromCenter {
    let sortOrder: Int
    let mark: WorksiteMapMark
    let deltaLatitude: Double
    let deltaLongitude: Double
    let distanceMeasure: Double
}
