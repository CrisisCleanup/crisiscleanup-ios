import Foundation

struct NetworkPointLocation: Codable {
    let point: NetworkLocationCoordinates
}

struct NetworkLocationCoordinates: Codable {
    let coordinates: [Double]
    let type: String
}

struct NetworkLocationUpdate: Codable {
    let user: Int64
    let point: NetworkLocationCoordinates
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case user,
             point,
             updatedAt = "updated_at"
    }
}
