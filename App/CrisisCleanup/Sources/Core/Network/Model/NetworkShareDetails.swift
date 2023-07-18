public struct NetworkShareDetails: Codable {
    let emails: [String]
    let phoneNumbers: [String]
    let shareMessage: String
    let noClaimReason: String?

    enum CodingKeys: String, CodingKey {
        case emails = "filename",
             phoneNumbers = "phone_numbers",
             shareMessage = "share_message",
             noClaimReason = "no_claim_reason_text"
    }
}
