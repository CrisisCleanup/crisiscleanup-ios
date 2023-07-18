import Foundation

public struct NetworkWorksitePush: Codable, Equatable {
    let id: Int64?
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String?
    let city: String
    let county: String
    let email: String?
    let favorite: NetworkType?
    let formData: [KeyDynamicValuePair]
    let incident: Int64
    let keyWorkType: NetworkWorkType?
    let location: NetworkWorksiteFull.Location
    let name: String
    let phone1: String
    let phone2: String?
    let plusCode: String?
    let postalCode: String?
    let reportedBy: Int64?
    let state: String
    let svi: Float?
    let updatedAt: Date
    let what3words: String?
    let workTypes: [NetworkWorkType]?

    let skipDuplicateCheck: Bool?
    let sendSms: Bool?

    enum CodingKeys: String, CodingKey {
        case id,
             address,
             autoContactFrequencyT = "auto_contact_frequency_t",
             caseNumber = "case_number",
             city,
             county,
             email,
             favorite,
             formData = "form_data",
             incident,
             keyWorkType = "key_work_type",
             location,
             name,
             phone1,
             phone2,
             plusCode = "pluscode",
             postalCode = "postal_code",
             reportedBy = "reported_by",
             state,
             svi,
             updatedAt = "updated_at",
             what3words = "what3words",
             workTypes = "work_types",
             skipDuplicateCheck = "skip_duplicate_check",
             sendSms = "send_sms"
    }
}
