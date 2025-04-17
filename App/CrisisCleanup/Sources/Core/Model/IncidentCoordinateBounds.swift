
public struct IncidentCoordinateBounds: Codable, Equatable {
    let incidentId: Int64
    let south: Double
    let west: Double
    let north: Double
    let east: Double
}

let IncidentCoordinateBoundsNone = IncidentCoordinateBounds(
    incidentId: 0,
    south: 0.0,
    west: 0.0,
    north: 0.0,
    east: 0.0
)
