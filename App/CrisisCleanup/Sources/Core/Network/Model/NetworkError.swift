struct ExpiredTokenError: Error {
    let message = "Auth token is expired"
}

public struct NetworkCrisisCleanupApiError: Codable, Equatable {
    let field: String
    let messages: [String]?

    var isExpiredToken: Bool { messages?.count == 1 && messages![0] == "Token has expired." }

    enum CodingKeys: String, CodingKey {
        case field
        case messages = "message"
    }

    public init(_ field: String, _ messages: [String]?) {
        self.field = field
        self.messages = messages
    }

    public init(from decoder: Decoder) throws {
        let values = try! decoder.container(keyedBy: CodingKeys.self)
        field = try values.decodeIfPresent(String.self, forKey: .field) ?? ""
        messages = values.decodeIterableString(CodingKeys.messages)
    }
}

extension Array where Element == NetworkCrisisCleanupApiError {
    func tryThrowException() throws {
        if isNotEmpty {
            let isExpiredToken = first { $0.isExpiredToken } != nil
            let error: Error = isExpiredToken ? ExpiredTokenError()
            : GenericError(condenseMessages)
            throw error
        }
    }

    var hasExpiredToken: Bool {
        first { $0.isExpiredToken } != nil
    }

    var condenseMessages: String {
        map { $0.messages?.joined(separator: ". ") ?? "" }
            .filter { $0.isNotBlank }
            .joined(separator: "\n")
    }
}
