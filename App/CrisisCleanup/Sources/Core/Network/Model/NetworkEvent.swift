import Foundation

public struct NetworkEvent: Codable, Equatable {
    let id: Int64
    let attr: [String: String?]
    let createdAt: Date
    let createdBy: Int64
    let eventKey: String
    let patientId: Int64?
    let patientModel: String?
    let event: Description

    enum CodingKeys: String, CodingKey {
        case id
        case attr
        case createdAt = "created_at"
        case createdBy = "created_by"
        case eventKey = "event_key"
        case patientId = "patient_id"
        case patientModel = "patient_model"
        case event = "event"
    }

    public struct Description: Codable, Equatable {
        let eventKey: String
        let eventDescriptionT: String
        let eventNameT: String

        enum CodingKeys: String, CodingKey {
            case eventKey = "event_key"
            case eventDescriptionT = "event_description_t"
            case eventNameT = "event_name_t"
        }
    }
}
