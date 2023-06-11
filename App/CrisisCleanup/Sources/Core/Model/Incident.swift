// sourcery: copyBuilder, skipCopyInit
public struct Incident {
    let id: Int64
    let name: String
    let shortName: String
    let locations: [IncidentLocation]
    let activePhoneNumbers: [String]
    let formFields: [IncidentFormField]
    let turnOnRelease: Bool
    let disasterLiteral: String

    // sourcery:begin: skipCopy
    lazy var disaster: Disaster = {
        disasterFromLiteral(disasterLiteral)
    }()

    lazy var formFieldLookup: [String: IncidentFormField] = {
        formFields.associateBy { $0.fieldKey }
    }()

    /// Form data fields categorized under a work type
    lazy var workTypeLookup: [String: String] = {
        formFields
            .filter { $0.selectToggleWorkType.isNotBlank }
            .associate { ($0.fieldKey, $0.selectToggleWorkType) }
    }()
    // sourcery:end

    init(
        id: Int64,
        name: String,
        shortName: String,
        locations: [IncidentLocation],
        activePhoneNumbers: [String],
        formFields: [IncidentFormField],
        turnOnRelease: Bool,
        disasterLiteral: String
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.locations = locations
        self.activePhoneNumbers = activePhoneNumbers
        self.formFields = formFields
        self.turnOnRelease = turnOnRelease
        self.disasterLiteral = disasterLiteral
    }
}

let EmptyIncident = Incident(
    id: -1,
    name: "",
    shortName: "",
    locations: [],
    activePhoneNumbers: [],
    formFields: [],
    turnOnRelease: false,
    disasterLiteral: ""
)

public struct IncidentLocation {
    let id: Int64
    let location: Int64
}

public struct IncidentFormField {
    let label: String
    let htmlType: String
    let group: String
    let help: String
    let placeholder: String
    let validation: String
    let valuesDefault: [String: String?]?
    let values: [String: String]
    let isCheckboxDefaultTrue: Bool
    let recurDefault: String
    let isRequired: Bool
    let isReadOnly: Bool
    let isReadOnlyBreakGlass: Bool
    let labelOrder: Int
    let listOrder: Int
    let isInvalidated: Bool
    let fieldKey: String
    let parentKey: String
    let selectToggleWorkType: String

    private lazy var htmlTypeLower = {
        htmlType.lowercased()
    }()
    lazy var isDivEnd: Bool = { htmlTypeLower == "divend" }()
    lazy var isHidden: Bool = { htmlTypeLower == "hidden" }()
    lazy var isFrequency: Bool = { htmlTypeLower == "cronselect" }()
}
