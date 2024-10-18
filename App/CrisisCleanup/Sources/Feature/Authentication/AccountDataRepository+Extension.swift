import Foundation

extension AccountDataRepository {
    func setAccount(
        _ accountProfile: NetworkUserProfile,
        refreshToken: String,
        accessToken: String,
        expiresIn: Int
    ) {
        with(accountProfile) { a in
            setAccount(
                refreshToken: refreshToken,
                accessToken: accessToken,
                id: a.id,
                email: a.email,
                firstName: a.firstName,
                lastName: a.lastName,
                expirySeconds: Int64(Date().timeIntervalSince1970) + Int64(expiresIn),
                profilePictureUri: a.profilePicUrl ?? "",
                org: OrgData(
                    id: a.organization.id,
                    name: a.organization.name
                ),
                hasAcceptedTerms: a.hasAcceptedTerms == true,
                activeRoles: a.activeRoles
            )
        }

    }
}
