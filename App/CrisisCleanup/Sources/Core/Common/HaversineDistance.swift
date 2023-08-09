import Foundation

// https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
private let earthRadiusKm = 6_371.0

/**
 * Distance in km
 *
 * Coordinates are in radians
 *
 * - SeeAlso Double.radians
 * - SeeAlso Double.kmToMiles
 */
func haversineDistance(
    _ latA: Double,
    _ lngA: Double,
    _ latB: Double,
    _ lngB: Double
) -> Double {
    let deltaLat = latA - latB
    let deltaLng = lngA - lngB
    let cosProduct = cos(latA) * cos(latB)
    let a = pow(sin(deltaLat) * 0.5, 2) + cosProduct * pow(sin(deltaLng) * 0.5, 2)
    let c = 2 * asin(sqrt(a).clamp(lower: -1.0, upper: 1.0))
    return earthRadiusKm * c
}
