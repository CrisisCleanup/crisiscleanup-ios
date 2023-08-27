public struct LocationLatLng: Equatable {
    let id: Int64
    let shape: LocationShape
    let multiCoordinates: [[LatLng]]
}

public struct LocationBounds: Equatable {
    let locationLatLng: LocationLatLng
    let multiBounds: [LatLngBounds?]
    let boundAreas: [Double]

    func containsLocation(_ location: LatLng) -> Bool {
        for i in locationLatLng.multiCoordinates.indices {
            if let latLngBounds = multiBounds[i] {
                if latLngBounds.bounds(location) {
                    let latLngs = locationLatLng.multiCoordinates[i]
                    if PolyUtil.containsLocation(location, latLngs) {
                        return true
                    }
                }
            }

        }
        return false
    }
}

public struct IncidentBounds: Equatable {
    let locations: [LocationBounds]
    let bounds: LatLngBounds
    let centroid: LatLng

    func containsLocation(_ location: LatLng) -> Bool {
        bounds.bounds(location) &&
        locations.first { $0.containsLocation(location) } != nil
    }
}

let DefaultIncidentBounds = IncidentBounds(
    locations: [],
    bounds: MapViewCameraBoundsDefault.bounds,
    centroid: MapViewCameraBoundsDefault.bounds.center)

struct LatLngBounds: Equatable {
    let southWest: LatLng
    let northEast: LatLng
    let center: LatLng

    init(southWest: LatLng, northEast: LatLng) {
        self.southWest = southWest
        self.northEast = northEast
        self.center = LatLng(
            (southWest.latitude + northEast.latitude) * 0.5,
            (southWest.longitude + northEast.longitude) * 0.5
        )
    }

    /// Assumes bounds does not span across the 180/-180 longitude line
    func bounds(_ location: LatLng) -> Bool {
        return location.latitude <= northEast.latitude &&
        location.latitude >= southWest.latitude &&
        location.longitude >= southWest.longitude &&
        location.longitude <= northEast.longitude
    }

    class Builder {
        private var south: Double = 0
        private var west: Double = 0
        private var north: Double = 0
        private var east: Double = 0

        private var isBuilding = false

        func include(_ latLng: LatLng) {
            if isBuilding {
                south = min(south, latLng.latitude)
                north = max(north, latLng.latitude)
                west = min(west, latLng.longitude)
                east = max(east, latLng.longitude)
            } else {
                isBuilding = true
                south = latLng.latitude
                north = latLng.latitude
                west = latLng.longitude
                east = latLng.longitude
            }
        }

        func build() -> LatLngBounds {
            if !isBuilding {
                fatalError("Lat-lng bounds builder did not include any coordinates before build")
            }

            let southWest = LatLng(south, west)
            let northEast = LatLng(north, east)
            return LatLngBounds(southWest: southWest, northEast: northEast)
        }
    }
}
