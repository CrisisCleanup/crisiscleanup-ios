import Foundation

struct LocalChange: Equatable {
    let isLocalModified: Bool
    let localModifiedAt: Date
    let syncedAt: Date
}
