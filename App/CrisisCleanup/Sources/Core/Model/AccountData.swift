import Foundation

public struct OrgData: Equatable {
    let id: Int64
    let name: String
}

// sourcery: copyBuilder
public struct AccountData {
    let id: Int64
    let tokenExpiry: Date
    let fullName: String
    let emailAddress: String
    let profilePictureUri: String
    let org: OrgData
    let areTokensValid: Bool

    func hasAuthenticated() -> Bool { id > 0 }

    func isAccessTokenExpired() -> Bool { tokenExpiry <= Date().addingTimeInterval(-10.minutes) }
}

let emptyOrgData = OrgData(id: 0, name: "")
let emptyAccountData = AccountData(
    id: 0,
    tokenExpiry: Date(timeIntervalSince1970: 0),
    fullName: "",
    emailAddress: "",
    profilePictureUri: "",
    org: emptyOrgData,
    areTokensValid: false
)
