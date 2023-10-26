import Foundation

public struct JoinOrgInvite {
    let token: String
    let orgId: Int64
    let expiresAt: Date

    var isExpired: Bool { expiresAt.isPast }
}
