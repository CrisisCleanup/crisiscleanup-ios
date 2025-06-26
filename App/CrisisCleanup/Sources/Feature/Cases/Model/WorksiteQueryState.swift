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
    let zoom: Double
    let coordinateBounds: CoordinateBounds
    let isTableView: Bool
    let tableViewSort: WorksiteSortBy
    let filters: CasesFilter
    let hasLocationPermission: Bool
}

let WorksiteQueryStateDefault = WorksiteQueryState(
    incidentId: EmptyIncident.id,
    zoom: 0,
    coordinateBounds: CoordinateBoundsDefault,
    isTableView: false,
    tableViewSort: .none,
    filters: CasesFilter(),
    hasLocationPermission: false
)
