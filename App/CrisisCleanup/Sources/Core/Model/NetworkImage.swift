import Foundation

struct NetworkImage: Equatable {
    let id: Int64
    let createdAt: Date
    let title: String
    let thumbnailUrl: String
    let imageUrl: String
    let tag: String
    let rotateDegrees: Int
}
