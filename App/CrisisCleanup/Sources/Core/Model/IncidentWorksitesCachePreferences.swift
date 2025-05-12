let BOUNDED_REGION_RADIUS_MILES_DEFAULT = 30.0

struct BoundedRegionParameters: Codable {
    let isRegionMyLocation: Bool
    let regionLatitude: Double
    let regionLongitude: Double
    let regionRadiusMiles: Double

    init(
        isRegionMyLocation: Bool = false,
        regionLatitude: Double = 0.0,
        regionLongitude: Double = 0.0,
        regionRadiusMiles: Double = 0.0
    ) {
        self.isRegionMyLocation = isRegionMyLocation
        self.regionLatitude = regionLatitude
        self.regionLongitude = regionLongitude
        self.regionRadiusMiles = regionRadiusMiles
    }
}

let BoundedRegionParametersNone = BoundedRegionParameters()

public struct IncidentWorksitesCachePreferences: Codable {
    let isPaused: Bool
    let isRegionBounded: Bool
    let boundedRegionParameters: BoundedRegionParameters

    let isAutoCache: Bool
    let isBoundedNearMe: Bool
    let isBoundedByCoordinates: Bool

    init(
        isPaused: Bool,
        isRegionBounded: Bool,
        boundedRegionParameters: BoundedRegionParameters
    ) {
        self.isPaused = isPaused
        self.isRegionBounded = isRegionBounded
        self.boundedRegionParameters = boundedRegionParameters

        isAutoCache = !(isPaused || isRegionBounded)
        isBoundedNearMe = isRegionBounded && boundedRegionParameters.isRegionMyLocation
        isBoundedByCoordinates = isRegionBounded && !boundedRegionParameters.isRegionMyLocation
    }
}

let InitialIncidentWorksitesCachePreferences = IncidentWorksitesCachePreferences(
    isPaused: false,
    isRegionBounded: false,
    boundedRegionParameters: BoundedRegionParametersNone,
)
