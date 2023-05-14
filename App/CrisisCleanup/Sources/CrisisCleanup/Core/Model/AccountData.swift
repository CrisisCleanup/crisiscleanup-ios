import Foundation

struct OrgData {
    let id: Int64
    let name: String
}

// sourcery: copyBuilder
struct AccountData {
    let id: Int64
    let accessToken: String
    let tokenExpiry: Date
    let fullName: String
    let emailAddress: String
    let profilePictureUri: String
    let org: OrgData

    var isTokenExpired: Bool {
        get { tokenExpiry <= Date() }
    }
    var isTokenInvalid: Bool {
        get { accessToken.isEmpty || isTokenExpired }
    }
}

let emptyOrgData = OrgData(id: 0, name: "")
let emptyAccountData = AccountData(
    id: 0,
    accessToken: "",
    tokenExpiry: Date(timeIntervalSince1970: 0),
    fullName: "",
    emailAddress: "",
    profilePictureUri: "",
    org: emptyOrgData
)
