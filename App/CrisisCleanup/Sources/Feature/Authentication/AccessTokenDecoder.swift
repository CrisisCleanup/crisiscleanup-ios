import Foundation

public protocol AccessTokenDecoder {
    func decode(_ accessToken: String) throws -> DecodedAccessToken
}

public struct DecodedAccessToken {
    let expiresAt: Date
}
