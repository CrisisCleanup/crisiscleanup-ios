import Foundation

protocol UuidGenerator {
    func uuid() -> String
}

class SwiftUuidGenerator: UuidGenerator {
    func uuid() -> String {
        UUID().uuidString
    }
}
