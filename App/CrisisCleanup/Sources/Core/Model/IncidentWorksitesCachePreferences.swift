let BOUNDED_REGION_RADIUS_MILES_DEFAULT = 30.0

struct BoundedRegionParameters {
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

public struct IncidentWorksitesCachePreferences {
    let isPaused: Bool
    let isRegionBounded: Bool
    let boundedRegionParameters: BoundedRegionParameters

    lazy var isAutoCache: Bool = {
        !(isPaused || isRegionBounded)
    }()

    lazy var isBoundedNearMe: Bool = {
        isRegionBounded && boundedRegionParameters.isRegionMyLocation
    }()

    lazy var isBoundedByCoordinates: Bool = {
        isRegionBounded && !boundedRegionParameters.isRegionMyLocation
    }()
}

let InitialIncidentWorksitesCachePreferences = IncidentWorksitesCachePreferences(
    isPaused: false,
    isRegionBounded: false,
    boundedRegionParameters: BoundedRegionParametersNone,
)
