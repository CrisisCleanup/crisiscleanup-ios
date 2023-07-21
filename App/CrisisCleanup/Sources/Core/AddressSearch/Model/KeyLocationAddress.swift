public struct KeyLocationAddress {
    public let key: String
    public let address: LocationAddress

    public init(key: String, address: LocationAddress) {
        self.key = key
        self.address = address
    }
}

extension Array where Element == KeyLocationAddress {
    public func sort(_ center: LatLng?) -> [KeyLocationAddress] {
        var sorted = self
        if let sortCenter = center {
            sorted = map {
                let distance = PolyUtil.computeSqrDistanceBetween($0.address.toLatLng(), sortCenter)
                return ($0, distance)
            }
            .sorted(by: { (a, b) in a.1 - b.1 < 0 })
            .map { $0.0 }
        }
        return sorted
    }
}
