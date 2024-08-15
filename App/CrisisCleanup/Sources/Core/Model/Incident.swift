// sourcery: copyBuilder, skipCopyInit
public struct Incident: Equatable {
    let id: Int64
    let name: String
    let shortName: String
    let caseLabel: String
    let locationIds: [Int64]
    let activePhoneNumbers: [String]
    let formFields: [IncidentFormField]
    let turnOnRelease: Bool
    let disasterLiteral: String

    // sourcery:begin: skipCopy
    let displayLabel: String
    let disaster: Disaster

    let formFieldLookup: [String: IncidentFormField]

    /// Form data fields categorized under a work type
    let workTypeLookup: [String: String]

    let isEmptyIncident: Bool
    // sourcery:end

    init(
        id: Int64,
        name: String,
        shortName: String,
        caseLabel: String,
        locationIds: [Int64],
        activePhoneNumbers: [String],
        formFields: [IncidentFormField],
        turnOnRelease: Bool,
        disasterLiteral: String
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.caseLabel = caseLabel
        self.locationIds = locationIds
        self.activePhoneNumbers = activePhoneNumbers
        self.formFields = formFields
        self.turnOnRelease = turnOnRelease
        self.disasterLiteral = disasterLiteral

        displayLabel = caseLabel.isBlank ? name : "\(caseLabel): \(name)"
        disaster = disasterFromLiteral(disasterLiteral)
        formFieldLookup = formFields.associateBy { $0.fieldKey }
        workTypeLookup = formFields
            .filter { $0.selectToggleWorkType.isNotBlank }
            .associate { ($0.fieldKey, $0.selectToggleWorkType) }
        isEmptyIncident = id <= 0
    }

    public static func == (lhs: Incident, rhs: Incident) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.shortName == rhs.shortName &&
        lhs.locationIds == rhs.locationIds &&
        lhs.activePhoneNumbers == rhs.activePhoneNumbers &&
        lhs.formFields == rhs.formFields &&
        lhs.turnOnRelease == rhs.turnOnRelease &&
        lhs.disasterLiteral == rhs.disasterLiteral
    }

    func asIdNameType() -> IncidentIdNameType {
        IncidentIdNameType(
            id: id,
            name: name,
            shortName: shortName,
            disasterLiteral: disasterLiteral
        )
    }
}

let EmptyIncident = Incident(
    id: -1,
    name: "",
    shortName: "",
    caseLabel: "",
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

public struct IncidentFormField: Equatable {
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

    // sourcery:begin: skipCopy
    let isDivEnd: Bool
    let isHidden: Bool
    let isFrequency: Bool
    let isSelectOption: Bool
    let isTextArea: Bool
    // sourcery:end

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
        isSelectOption = htmlTypeLower == "select"
        isTextArea = htmlTypeLower == "textarea"
    }

    func translatedLabel(_ translator: KeyTranslator) -> String {
        let labelTranslateKey = "formLabels.\(fieldKey)"
        var translatedLabel = translator.t(labelTranslateKey)
        if translatedLabel == labelTranslateKey {
            translatedLabel = label
        }
        return translatedLabel
    }
}

public struct IncidentIdNameType: Equatable {
    let id: Int64
    let name: String
    let shortName: String
    let disasterLiteral: String
}

let EmptyIncidentIdNameType = EmptyIncident.asIdNameType()
