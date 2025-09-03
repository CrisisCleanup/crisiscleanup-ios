import Foundation

// sourcery: copyBuilder, skipCopyInit
public struct IncidentWorksitesCachePreferences: Codable, Equatable {
    let isPaused: Bool
    let isRegionBounded: Bool
    let boundedRegionParameters: BoundedRegionParameters
    let lastReconciled: Date?

    // sourcery:begin: skipCopy
    let isAutoCache: Bool
    let isBoundedNearMe: Bool
    let isBoundedByCoordinates: Bool
    // sourcery:end

    init(
        isPaused: Bool,
        isRegionBounded: Bool,
        boundedRegionParameters: BoundedRegionParameters,
        lastReconciled: Date? = nil,
    ) {
        self.isPaused = isPaused
        self.isRegionBounded = isRegionBounded
        self.boundedRegionParameters = boundedRegionParameters
        self.lastReconciled = lastReconciled

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
