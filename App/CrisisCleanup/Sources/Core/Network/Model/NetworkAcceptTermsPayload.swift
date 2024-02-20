import Foundation

struct NetworkAcceptTermsPayload: Codable, Equatable {
    let acceptedTerms: Bool
    let acceptedTermsTimestamp: String

    enum CodingKeys: String, CodingKey {
        case acceptedTerms = "accepted_terms",
             acceptedTermsTimestamp = "accepted_terms_timestamp"
    }
}
