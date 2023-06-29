struct CoordinateBounds {
    let southWest: LatLng
    let northEast: LatLng
}

let CoordinateBoundsDefault = CoordinateBounds(
    southWest: DefaultBounds.southWest,
    northEast: DefaultBounds.northEast
)

// sourcery: copyBuilder
struct WorksiteQueryState {
    let incidentId: Int64
    let q: String
    let zoom: Double
    let coordinateBounds: CoordinateBounds
    let isTableView: Bool
    let isZoomInteractive: Bool
    // TODO Filters and additional
}

let WorksiteQueryStateDefault = WorksiteQueryState(
    incidentId: EmptyIncident.id,
    q: "",
    zoom: 0,
    coordinateBounds: CoordinateBoundsDefault,
    isTableView: false,
    isZoomInteractive: false
)
