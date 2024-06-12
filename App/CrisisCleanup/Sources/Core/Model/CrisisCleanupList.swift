import Foundation

struct CrisisCleanupList {
    let id: Int64
    let updatedAt: Date
    let networkId: Int64
    let parentNetworkId: Int64?
    let name: String
    let description: String
    let listOrder: Int64?
    let tags: String?
    let model: ListModel
    let objectIds: [Int64]
    let shared: ListShare
    let permission: ListPermission
    let incident: IncidentIdNameType?
}

let EmptyList = CrisisCleanupList(
    id: 0,
    updatedAt: Date.init(timeIntervalSince1970: 0),
    networkId: 0,
    parentNetworkId: nil,
    name: "",
    description: "",
    listOrder: nil,
    tags: nil,
    model: .none,
    objectIds: [],
    shared: .private,
    permission: .read,
    incident: IncidentIdNameType(id: EmptyIncident.id, name: "", shortName: "", disasterLiteral: "")
)

enum ListModel: String, Identifiable, CaseIterable {
    case none,
         file,
         incident,
         list,
         organization,
         organizationIncidentTeam,
         user,
         worksite

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .none: return ""
        case .file: return "file_files"
        case .incident: return "incident_incidents"
        case .list: return "list_lists"
        case .organization: return "organization_organizations"
        case .organizationIncidentTeam: return "organization_organizations_incidents_teams"
        case .user: return "user_users"
        case .worksite: return "worksite_worksites"
        }
    }
}

private let modelLiteralLookup = ListModel.allCases.associateBy { $0.literal }

func listModelFromLiteral(_ literal: String) -> ListModel {
    modelLiteralLookup[literal] ?? .none
}

enum ListPermission: String, Identifiable, CaseIterable {
    case read,
         readCopy,
         readWriteCopy,
         readWriteDeleteCopy

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .read: return "read_only"
        case .readCopy: return "read_copy"
        case .readWriteCopy: return "read_write_copy"
        case .readWriteDeleteCopy: return "read_write_delete_copy"
        }
    }
}

private let permissionLiteralLookup = ListPermission.allCases.associateBy { $0.literal }

func listPermissionFromLiteral(_ literal: String) -> ListPermission {
    permissionLiteralLookup[literal] ?? .read
}

enum ListShare: String, Identifiable, CaseIterable {
    case all,
         groupAffiliates,
         organization,
         `private`,
         `public`,
         team

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .all: return "all"
        case .groupAffiliates: return "groups_affiliates"
        case .organization: return "organization"
        case .private: return "private"
        case .public: return "public"
        case .team: return "team"
        }
    }
}

private let shareLiteralLookup = ListShare.allCases.associateBy { $0.literal }

func listShareFromLiteral(_ literal: String) -> ListShare {
    shareLiteralLookup[literal] ?? .private
}
