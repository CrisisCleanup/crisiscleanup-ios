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
    let activeRoles: Set<Int>

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
        incidentIds: Set<Int64> = Set(),
        activeRoles: Set<Int> = Set()
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
        self.activeRoles = activeRoles
    }
}

fileprivate let whitespacePattern = #/\s/#

fileprivate func defaultProfilePictureUri(_ fullName: String) -> String {
    let seed = fullName.replacing(whitespacePattern, with: "-")
    return fullName.isBlank ? "" : "https://api.dicebear.com/9.x/pixel-art/svg?seed=\(seed)"
}

extension AccountInfo {
    func asAccountData() -> AccountData {
        let tokenExpiry = Date(timeIntervalSince1970: Double(expirySeconds))
        let fullName = "\(firstName) \(lastName)"
        let orgData = OrgData(id: orgId, name: orgName)
        let ppUri = profilePictureUri.ifBlank { defaultProfilePictureUri(fullName) }
        let isGeneratedProfilePicture = profilePictureUri.isBlank
        return AccountData(
            id: id,
            tokenExpiry: tokenExpiry,
            fullName: fullName,
            emailAddress: email,
            profilePictureUri: ppUri,
            org: orgData,
            hasAcceptedTerms: hasAcceptedTerms,
            approvedIncidents: incidentIds,
            isCrisisCleanupAdmin: activeRoles.contains(1),
            // Overwrite downstream
            areTokensValid: tokenExpiry > Date(),
            isGeneratedProfilePicture: isGeneratedProfilePicture,
        )
    }
}
