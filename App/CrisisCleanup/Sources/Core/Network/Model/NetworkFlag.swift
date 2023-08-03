import Foundation

public struct NetworkFlag: Codable, Equatable {
    // Incoming network ID is always defined
    let id: Int64?
    let action: String?
    let createdAt: Date
    let isHighPriority: Bool?
    let notes: String?
    let reasonT: String
    let requestedAction: String?

    let attr: FlagAttributes?

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case createdAt = "created_at"
        case isHighPriority = "is_high_priority"
        case notes
        case reasonT = "reason_t"
        case requestedAction = "requested_action"
        case attr
    }

    public struct FlagAttributes: Codable, Equatable {
        let involvesYou: String?
        let haveContactedOtherOrg: String?
        let organizations: [Int64]?

        enum CodingKeys: String, CodingKey {
            case involvesYou = "involves_you",
                 haveContactedOtherOrg = "have_you_contacted_org",
                 organizations
        }
    }
}

public struct NetworkFlagId: Codable, Equatable {
    let flagId: Int64

    enum CodingKeys: String, CodingKey {
        case flagId = "flag_id"
    }
}
