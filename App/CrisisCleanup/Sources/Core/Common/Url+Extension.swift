import Foundation

public extension [URLQueryItem] {
    func find(_ name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}
