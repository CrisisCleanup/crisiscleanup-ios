import Foundation

struct NetworkCaseHistoryResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let events: [NetworkCaseHistoryEvent]?
}

public struct NetworkCaseHistoryEvent: Codable, Equatable {
    let id: Int64
    let eventKey: String
    let createdAt: Date
    let createdBy: Int64
    let pastTenseT: String
    let actorLocationName: String?
    let recipientLocationName: String?
    let attr: NetworkCaseHistoryAttrs

    enum CodingKeys: String, CodingKey {
        case id,
             eventKey = "event_key",
             createdAt = "created_at",
             createdBy = "created_by",
             pastTenseT = "past_tense_t",
             actorLocationName = "actor_location_name",
             recipientLocationName = "recipient_location_name",
             attr
    }
}

public struct NetworkCaseHistoryAttrs: Codable, Equatable {
    let incidentName: String
    let patientCaseNumber: String?
    let patientId: Int64?
    let patientLabelT: String?
    let patientLocationName: String?
    let patientNameT: String?
    let patientReasonT: String?
    let patientStatusNameT: String?
    let recipientCaseNumber: String?
    let recipientId: Int64?
    let recipientName: String?
    let recipientNameT: String?

    enum CodingKeys: String, CodingKey {
        case incidentName = "incident_name",
             patientCaseNumber = "patient_case_number",
             patientId = "patient_id",
             patientLabelT = "patient_label_t",
             patientLocationName = "patient_location_name",
             patientNameT = "patient_name_t",
             patientReasonT = "patient_reason_t",
             patientStatusNameT = "patient_status_name_t",
             recipientCaseNumber = "recipient_case_number",
             recipientId = "recipient_id",
             recipientName = "recipient_name",
             recipientNameT = "recipient_name_t"
    }
}
