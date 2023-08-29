// sourcery: copyBuilder, skipCopyInit
struct FieldDynamicValue {
    let field: IncidentFormField
    let selectOptions: [String: String]
    let childKeys: Set<String>
    let nestLevel: Int
    let dynamicValue: DynamicValue
    let workTypeStatus: WorkTypeStatus

    // sourcery:begin: skipCopy
    var key: String { field.fieldKey }
    var childrenCount: Int { childKeys.count }

    let breakGlass: FieldEditProperties
    let isWorkTypeGroup: Bool
    // sourcery:end

    init(
        _ field: IncidentFormField,
        _ selectOptions: [String: String],
        childKeys: Set<String> = [],
        nestLevel: Int = 0,
        dynamicValue: DynamicValue = DynamicValue(""),
        workTypeStatus: WorkTypeStatus = .openUnassigned
    ) {
        self.field = field
        self.selectOptions = selectOptions
        self.childKeys = childKeys
        self.nestLevel = nestLevel
        self.dynamicValue = dynamicValue
        breakGlass = FieldEditProperties(field.isReadOnlyBreakGlass)
        self.workTypeStatus = workTypeStatus
        isWorkTypeGroup = field.parentKey == WorkFormGroupKey
    }
}

class FieldEditProperties {
    let isGlass: Bool
    var isGlassBroken = false

    var isNotEditable: Bool { isGlass && !isGlassBroken }

    private var brokenGlassFocus = true

    init(_ isGlass: Bool = false) {
        self.isGlass = isGlass
    }

    func takeBrokenGlassFocus() -> Bool {
        if (brokenGlassFocus) {
            brokenGlassFocus = false
            return true
        }
        return false
    }
}
