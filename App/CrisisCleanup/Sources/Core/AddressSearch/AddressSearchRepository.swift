public protocol AddressSearchRepository {
    func clearCache()

    func getAddress(_ coordinates: LatLng) async -> LocationAddress?

    func startSearchSession()

    @MainActor func searchAddresses(
        _ query: String,
        countryCodes: [String],
        center: LatLng?,
        southwest: LatLng?,
        northeast: LatLng?,
        maxResults: Int
    ) async -> [KeySearchAddress]

    func getPlaceAddress(_ placeId: String) async throws -> LocationAddress?
}

extension AddressSearchRepository {
    public func searchAddresses(
        _ query: String,
        countryCodes: [String] = [],
        center: LatLng? = nil,
        southwest: LatLng? = nil,
        northeast: LatLng? = nil,
        maxResults: Int = 10
    ) async -> [KeySearchAddress] {
        await searchAddresses(
            query,
            countryCodes: countryCodes,
            center: center,
            southwest: southwest,
            northeast: northeast,
            maxResults: maxResults
        )
    }
}
