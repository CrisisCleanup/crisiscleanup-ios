import Foundation

public struct JoinOrgInvite {
    let token: String
    let orgId: Int64
    let expiresAt: Date

    var isExpired: Bool { expiresAt.isPast }
}

public enum JoinOrgResult {
    case success,
         /// Already joined
         redundant,
         pendingAdditionalAction,
         unknown
}
