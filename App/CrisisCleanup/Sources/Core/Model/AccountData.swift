import Foundation

public struct OrgData: Equatable {
    let id: Int64
    let name: String
}

// sourcery: copyBuilder
public struct AccountData: Equatable {
    let id: Int64
    let tokenExpiry: Date
    let fullName: String
    let emailAddress: String
    let profilePictureUri: String
    let org: OrgData
    let hasAcceptedTerms: Bool
    let approvedIncidents: Set<Int64>
    let areTokensValid: Bool

    // sourcery:begin: skipCopy
    var hasAuthenticated: Bool { id > 0 }

    var isAccessTokenExpired: Bool { tokenExpiry <= Date().addingTimeInterval(-10.minutes) }
    // sourcery:end
}

let emptyOrgData = OrgData(id: 0, name: "")
let emptyAccountData = AccountData(
    id: 0,
    tokenExpiry: Date(timeIntervalSince1970: 0),
    fullName: "",
    emailAddress: "",
    profilePictureUri: "",
    org: emptyOrgData,
    hasAcceptedTerms: false,
    approvedIncidents: Set(),
    areTokensValid: false
)
