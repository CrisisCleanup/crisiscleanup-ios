public protocol LocationAreaBounds {
    func isInBounds(_ latitude: Double, _ longitude: Double) -> Bool
}

public struct OrganizationLocationAreaBounds {
    let primary: LocationAreaBounds?
    let secondary: LocationAreaBounds?

    init(
        _ primary: LocationAreaBounds? = nil,
        _ secondary: LocationAreaBounds? = nil
    ) {
        self.primary = primary
        self.secondary = secondary
    }
}

public protocol LocationBoundsConverter {
    func convert(_ location: Location) -> LocationAreaBounds
}
