import AuthenticationServices
import Foundation

protocol SecureDataSource {
    func getAuthTokens(_ userId: Int64) -> (String, String)

    func saveAuthTokens(
        _ userId: Int64,
        _ refreshToken: String,
        _ accessToken: String
    ) throws

    func deleteAuthTokens(_ userId: Int64)
}

class KeychainDataSource: SecureDataSource {
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private let bundleId: String?

    private var serviceAttribute: String {
        let bundle = bundleId ?? "crisis-cleanup"
        return "\(bundle)-account-data"
    }

    init(_ bundleId: String = "") {
        jsonEncoder = JsonEncoderFactory().encoder()
        jsonDecoder = JsonDecoderFactory().decoder()

        self.bundleId = bundleId.ifBlank { Bundle.main.bundleIdentifier }
    }

    private func getAccountIdentifier(_ userId: Int64) -> String {
        "crisis-cleanup-account-\(userId)"
    }

    func getAuthTokens(_ userId: Int64) -> (String, String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: getAccountIdentifier(userId),
            kSecReturnData: true
        ] as [CFString : Any]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data {
            let accountData = try? jsonDecoder.decode(PrivateAccountData.self, from: data)
            return (
                accountData?.refreshToken ?? "",
                accountData?.accessToken ?? ""
            )
        }

        return ("", "")
    }

    func saveAuthTokens(
        _ userId: Int64,
        _ refreshToken: String,
        _ accessToken: String
    ) throws {
        guard userId > 0 else {
            return
        }

        guard let encodedData = try? jsonEncoder.encode(
            PrivateAccountData(
                refreshToken: refreshToken,
                accessToken: accessToken
            )
        ) else {
            throw GenericError("Unable to encode access token for secure storage")
        }

        var query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: getAccountIdentifier(userId)
        ] as [CFString : Any]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attributesToUpdate = [
                String(kSecValueData): encodedData
            ]

            let updateStatus = SecItemUpdate(
                query as CFDictionary,
                attributesToUpdate as CFDictionary
            )
            if updateStatus != errSecSuccess {
                throw GenericError("Failed to update secure access token. \(updateStatus.message)")
            }

        case errSecItemNotFound:
            query[String(kSecValueData) as CFString] = encodedData

            let insertStatus = SecItemAdd(query as CFDictionary, nil)
            if insertStatus != errSecSuccess {
                throw GenericError("Failed to add secure access token. \(insertStatus.message)")
            }
        default:
            throw GenericError("Secure store error: \(status.message)")
        }
    }

    func deleteAuthTokens(_ userId: Int64) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: getAccountIdentifier(userId)
        ] as [CFString : Any]
        SecItemDelete(query as CFDictionary)
    }
}

extension OSStatus {
    var message: String {
        (SecCopyErrorMessageString(self, nil) ?? "" as CFString) as String
    }
}

private struct PrivateAccountData: Codable {
    let refreshToken: String
    let accessToken: String
}
