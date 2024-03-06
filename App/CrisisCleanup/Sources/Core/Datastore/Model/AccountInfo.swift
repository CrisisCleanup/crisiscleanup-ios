import Foundation

// sourcery: copyBuilder
struct AccountInfo: Codable {
    let id: Int64
    let email: String
    let firstName: String
    let lastName: String
    let expirySeconds: Int64
    let profilePictureUri: String
    let accessToken: String
    let orgId: Int64
    let orgName: String
    let hasAcceptedTerms: Bool
    let incidentIds: Set<Int64>

    init(
        id: Int64 = 0,
        email: String = "",
        firstName: String = "",
        lastName: String = "",
        expirySeconds: Int64 = 0,
        profilePictureUri: String = "",
        accessToken: String = "",
        orgId: Int64 = 0,
        orgName: String = "",
        hasAcceptedTerms: Bool = false,
        incidentIds: Set<Int64> = Set()
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
        self.hasAcceptedTerms = hasAcceptedTerms
        self.incidentIds = incidentIds
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
            tokenExpiry: tokenExpiry,
            fullName: fullName,
            emailAddress: email,
            profilePictureUri: ppUri,
            org: orgData,
            hasAcceptedTerms: hasAcceptedTerms,
            approvedIncidents: incidentIds,
            // Overwrite downstream
            areTokensValid: tokenExpiry > Date()
        )
    }
}
