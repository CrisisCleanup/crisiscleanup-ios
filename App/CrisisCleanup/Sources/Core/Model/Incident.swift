// sourcery: copyBuilder, skipCopyInit
public struct Incident {
    let id: Int64
    let name: String
    let shortName: String
    let locationIds: [Int64]
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
        locationIds: [Int64],
        activePhoneNumbers: [String],
        formFields: [IncidentFormField],
        turnOnRelease: Bool,
        disasterLiteral: String
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.locationIds = locationIds
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
    locationIds: [],
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

    let isDivEnd: Bool
    let isHidden: Bool
    let isFrequency: Bool

    init(
        label: String,
        htmlType: String,
        group: String,
        help: String,
        placeholder: String,
        validation: String,
        valuesDefault: [String : String?]?,
        values: [String : String],
        isCheckboxDefaultTrue: Bool,
        recurDefault: String,
        isRequired: Bool,
        isReadOnly: Bool,
        isReadOnlyBreakGlass: Bool,
        labelOrder: Int,
        listOrder: Int,
        isInvalidated: Bool,
        fieldKey: String,
        parentKey: String,
        selectToggleWorkType: String
    ) {
        self.label = label
        self.htmlType = htmlType
        self.group = group
        self.help = help
        self.placeholder = placeholder
        self.validation = validation
        self.valuesDefault = valuesDefault
        self.values = values
        self.isCheckboxDefaultTrue = isCheckboxDefaultTrue
        self.recurDefault = recurDefault
        self.isRequired = isRequired
        self.isReadOnly = isReadOnly
        self.isReadOnlyBreakGlass = isReadOnlyBreakGlass
        self.labelOrder = labelOrder
        self.listOrder = listOrder
        self.isInvalidated = isInvalidated
        self.fieldKey = fieldKey
        self.parentKey = parentKey
        self.selectToggleWorkType = selectToggleWorkType

        let htmlTypeLower = htmlType.lowercased()
        isDivEnd = htmlTypeLower == "divend"
        isHidden = htmlTypeLower == "hidden"
        isFrequency = htmlTypeLower == "cronselect"
    }
}
