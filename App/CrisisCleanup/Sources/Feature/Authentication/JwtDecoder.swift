import Foundation
import JWTDecode

struct AccessTokenError: Error { }

class JwtDecoder: AccessTokenDecoder {
    func decode(_ accessToken: String) throws -> DecodedAccessToken {
        let jwt = try? JWTDecode.decode(jwt: accessToken)
        if let expiresAt = jwt?.expiresAt {
            return DecodedAccessToken(expiresAt: expiresAt)
        }
        throw AccessTokenError()
    }
}
