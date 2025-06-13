import Foundation

public struct NetworkIncidentsResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkIncident]?
}

public struct NetworkIncidentResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let incident: NetworkIncident?
}

public struct NetworkIncidentLocation: Codable, Equatable {
    let id: Int64
    let location: Int64

    init(
        _ id: Int64,
        _ location: Int64
    ) {
        self.id = id
        self.location = location
    }
}

public struct NetworkIncident: Codable, Equatable {
    let id: Int64
    let startAt: Date
    let name: String
    let shortName: String
    let caseLabel: String
    let locations: [NetworkIncidentLocation]
    let type: String
    let activePhoneNumber: [Int64]?
    let turnOnRelease: Bool
    let isArchived: Bool?

    let fields: [NetworkIncidentFormField]?

    enum CodingKeys: String, CodingKey {
        case id
        case startAt = "start_at"
        case name
        case shortName = "short_name"
        case caseLabel = "case_label"
        case locations
        case type = "incident_type"
        case activePhoneNumber = "active_phone_number"
        case turnOnRelease = "turn_on_release"
        case isArchived = "is_archived"
        case fields = "form_fields"
    }

    public init(
        id: Int64,
        startAt: Date,
        name: String,
        shortName: String,
        caseLabel: String,
        locations: [NetworkIncidentLocation],
        type: String,
        activePhoneNumber: [Int64]?,
        turnOnRelease: Bool,
        isArchived: Bool?,
        fields: [NetworkIncidentFormField]? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.name = name
        self.shortName = shortName
        self.caseLabel = caseLabel
        self.locations = locations
        self.type = type
        self.activePhoneNumber = activePhoneNumber
        self.turnOnRelease = turnOnRelease
        self.isArchived = isArchived
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.startAt = try container.decode(Date.self, forKey: .startAt)
        self.name = try container.decode(String.self, forKey: .name)
        self.shortName = try container.decode(String.self, forKey: .shortName)
        self.caseLabel = try container.decode(String.self, forKey: .caseLabel)
        self.locations = try container.decode([NetworkIncidentLocation].self, forKey: .locations)
        self.type = try container.decode(String.self, forKey: .type)
        self.activePhoneNumber = container.decodeIterableInt64(.activePhoneNumber)
        self.turnOnRelease = try container.decode(Bool.self, forKey: .turnOnRelease)
        self.isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived)
        self.fields = try container.decodeIfPresent([NetworkIncidentFormField].self, forKey: .fields)
    }
}

public struct NetworkIncidentFormField: Codable, Equatable {
    let label: String
    let htmlType: String
    let dataGroup: String
    let help: String?
    let placeholder: String?
    let readOnlyBreakGlass: Bool
    let valuesDefault: [String: String?]?
    let orderLabel: Int?
    let validation: String?
    let recurDefault: String?
    let values: [FormFieldValue]?
    let isRequired: Bool?
    let isReadOnly: Bool?
    let listOrder: Int
    let invalidatedAt: Date?
    let fieldKey: String
    let fieldParentKey: String?
    let selectToggleWorkType: String?

    enum CodingKeys: String, CodingKey {
        case label = "label_t"
        case htmlType = "html_type"
        case dataGroup = "data_group"
        case help = "help_t"
        case placeholder = "placeholder_t"
        case readOnlyBreakGlass = "read_only_break_glass"
        case valuesDefault = "values_default_t"
        case orderLabel = "order_label"
        case validation
        case recurDefault = "recur_default"
        case values
        case isRequired = "is_required"
        case isReadOnly = "is_read_only"
        case listOrder = "list_order"
        case invalidatedAt = "invalidated_at"
        case fieldKey = "field_key"
        case fieldParentKey = "field_parent_key"
        case selectToggleWorkType = "if_selected_then_work_type"
    }

    var isCheckboxDefaultTrue: Bool {
        htmlType == "checkbox" && valuesDefault?.count == 1 && valuesDefault?["value"] == "true"
    }
}

public struct FormFieldValue: Codable, Equatable {
    let value: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case value
        case name = "name_t"
    }
}

public struct NetworkIncidentsListResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkIncidentShort]?
}

public struct NetworkIncidentShort: Codable, Equatable {
    let id: Int64
    let name: String
    let shortName: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case type = "incident_type"
    }
}
