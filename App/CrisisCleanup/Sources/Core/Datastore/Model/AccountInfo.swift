import Foundation

// sourcery: copyBuilder
struct AccountInfo: Codable {
    // TODO: Move access token into credentials manager
    let id: Int64
    let email: String
    let firstName: String
    let lastName: String
    let expirySeconds: Int64
    let profilePictureUri: String
    let accessToken: String
    let orgId: Int64
    let orgName: String

    init(
        id: Int64 = 0,
        email: String = "",
        firstName: String = "",
        lastName: String = "",
        expirySeconds: Int64 = 0,
        profilePictureUri: String = "",
        accessToken: String = "",
        orgId: Int64 = 0,
        orgName: String = ""
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.expirySeconds = expirySeconds
        self.profilePictureUri = profilePictureUri
        self.accessToken = accessToken
        self.orgId = orgId
        self.orgName = orgName
    }
}

fileprivate func defaultProfilePictureUri(_ fullName: String) -> String {
    fullName.isBlank ? "" : "https://avatars.dicebear.com/api/bottts/\(fullName).svg"
}

extension AccountInfo {
    func asAccountData() -> AccountData {
        let tokenExpiry = Date(timeIntervalSince1970: Double(expirySeconds))
        let fullName = "\(firstName) \(lastName)"
        let orgData = OrgData(id: orgId, name: orgName)
        let ppUri = profilePictureUri.ifBlank { defaultProfilePictureUri(fullName) }
        return AccountData(
            id: id,
            accessToken: accessToken,
            tokenExpiry: tokenExpiry,
            fullName: fullName,
            emailAddress: email,
            profilePictureUri: ppUri,
            org: orgData
        )
    }
}
