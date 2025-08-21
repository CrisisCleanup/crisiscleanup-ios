struct NetworkTransferOrganizationPayload: Codable {
    let action: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case action = "transfer_action",
             token = "invitation_token"
    }
}

struct NetworkTransferOrganizationResult: Codable {
    let status: String
}
