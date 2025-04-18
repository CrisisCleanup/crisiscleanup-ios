
internal extension LatLngBounds {
    func asIncidentCoordinateBounds(_ incidentId: Int64) -> IncidentCoordinateBounds {
        return IncidentCoordinateBounds(
            incidentId: incidentId,
            south: southWest.latitude,
            west: southWest.longitude,
            north: northEast.latitude,
            east: northEast.longitude,
        )
    }
}
