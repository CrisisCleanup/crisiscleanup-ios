import AuthenticationServices
import Foundation

protocol SecureDataSource {
    func getAccessToken(_ emailAddress: String) -> String

    func saveAccessToken(
        _ emailAddress: String,
        _ accessToken: String
    ) throws

    func deleteAccessToken(_ emailAddress: String)
}

class KeychainDataSource: SecureDataSource {
    private let bundleId: String?

    private var serviceAttribute: String {
        let bundle = bundleId ?? "crisis-cleanup"
        return "\(bundle)-account"
    }

    init(_ bundleId: String = "") {
        self.bundleId = bundleId.isBlank ? Bundle.main.bundleIdentifier : bundleId
    }

    func getAccessToken(_ emailAddress: String) -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: emailAddress,
            kSecReturnData: true
        ] as [CFString : Any]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data {
            return String(decoding: data, as: UTF8.self)
        }

        return ""
    }

    func saveAccessToken(
        _ emailAddress: String,
        _ accessToken: String
    ) throws {
        guard emailAddress.isNotBlank else {
            return
        }

        guard let encodedToken = accessToken.data(using: .utf8) else {
            throw GenericError("Unable to encode access token for secure storage")
        }

        var query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: emailAddress
        ] as [CFString : Any]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attributesToUpdate = [
                String(kSecValueData): encodedToken
            ]

            let updateStatus = SecItemUpdate(
                query as CFDictionary,
                attributesToUpdate as CFDictionary
            )
            if updateStatus != errSecSuccess {
                throw GenericError("Failed to update secure access token. \(updateStatus.message)")
            }

        case errSecItemNotFound:
            query[String(kSecValueData) as CFString] = encodedToken

            let insertStatus = SecItemAdd(query as CFDictionary, nil)
            if insertStatus != errSecSuccess {
                throw GenericError("Failed to add secure access token. \(insertStatus.message)")
            }
        default:
            throw GenericError("Secure store error: \(status.message)")
        }
    }

    func deleteAccessToken(_ emailAddress: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceAttribute,
            kSecAttrAccount: emailAddress
        ] as [CFString : Any]
        SecItemDelete(query as CFDictionary)
    }
}

extension OSStatus {
    var message: String {
        (SecCopyErrorMessageString(self, nil) ?? "" as CFString) as String
    }
}
