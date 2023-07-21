public struct LocationAddress {
    public let latitude: Double
    public let longitude: Double
    public let address: String
    public let city: String
    public let county: String
    public let state: String
    public let country: String
    public let zipCode: String

    public init(
        latitude: Double,
        longitude: Double,
        address: String,
        city: String,
        county: String,
        state: String,
        country: String,
        zipCode: String
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.county = county
        self.state = state
        self.country = country
        self.zipCode = zipCode
    }
}
