import Foundation

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 256_000_000, diskCapacity: 1_000_000_000)
}
