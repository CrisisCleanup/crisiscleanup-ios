let BOUNDED_REGION_RADIUS_MILES_DEFAULT = 30.0

// sourcery: copyBuilder, skipCopyInit
struct BoundedRegionParameters: Codable, Equatable {
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
