import Foundation

let DetailsFormGroupKey = "property_info"
let WorkFormGroupKey = "work_info"
let HazardsFormGroupKey = "hazards_info"
let VolunteerReportFormGroupKey = "claim_status_report_info"

fileprivate struct FormFieldKeys: Hashable {
    static func make(_ formField: IncidentFormField) -> FormFieldKeys {
        FormFieldKeys(formField.parentKey, formField.fieldKey)
    }

    let parent: String
    let field: String

    init(_ parentKey: String, _ fieldKey: String) {
        self.parent = parentKey
        self.field = fieldKey
    }
}

// sourcery: copyBuilder, skipCopyInit
public struct FormFieldNode {
    var id = UUID()

    static func make(
        formField: IncidentFormField,
        children: [FormFieldNode],
        options: [String : String]
    ) -> FormFieldNode {
        FormFieldNode(
            formField: formField,
            children: children,
            options: options,
            fieldKey: formField.fieldKey,
            parentKey: formField.parentKey,
            isRootNode: formField.fieldKey.isEmpty
        )
    }

    let formField: IncidentFormField
    let children: [FormFieldNode]
    let options: [String: String]
    let fieldKey: String
    let parentKey: String
    let isRootNode: Bool

    init(
        formField: IncidentFormField,
        children: [FormFieldNode],
        options: [String : String],
        fieldKey: String,
        parentKey: String,
        isRootNode: Bool
    ) {
        self.formField = formField
        self.children = children
        self.options = options
        self.fieldKey = fieldKey
        self.parentKey = parentKey
        self.isRootNode = isRootNode
    }

    static func buildTree(
        _ formFields: [IncidentFormField],
        _ keyTranslator: KeyTranslator
    ) -> [FormFieldNode] {
        let inputFormFields = formFields.filter { !$0.isHidden }

        var lookup: [FormFieldKeys: IncidentFormField] = [FormFieldKeys("", ""): EmptyIncidentFormField]
        inputFormFields.forEach { lookup[FormFieldKeys.make($0)] = $0 }

        var groupedByParent = [String: [IncidentFormField]]()
        inputFormFields.forEach {
            let parentKey = $0.parentKey
            if !groupedByParent.keys.contains(parentKey) {
                groupedByParent[parentKey] = []
            }
            groupedByParent[parentKey]!.append($0)
        }
        var sortedByParent = [String: [IncidentFormField]]()
        for (key, value) in groupedByParent {
            let sorted = value.sorted { a, b in
                let aListOrder = a.listOrder
                let bListOrder = b.listOrder
                if aListOrder == bListOrder {
                    return a.labelOrder < b.labelOrder
                }
                return aListOrder < bListOrder
            }
            sortedByParent[key] = sorted
        }

        func buildNode(_ parentKey: String, _ fieldKey: String) -> FormFieldNode {
            let children =
            sortedByParent[fieldKey]?.map { buildNode($0.parentKey, $0.fieldKey) } ?? []
            let formField = lookup[FormFieldKeys(parentKey, fieldKey)]!
            let options = formField.values.isNotEmpty ? formField.values : {
                var optionLookup = [String: String]()
                for (key, value) in (formField.valuesDefault ?? [:]) {
                    optionLookup[key] = value ?? ""
                }
                return optionLookup
            }()
            var translatedOptions = [String: String]()
            for (key, value) in options {
                let phraseKey = value
                let translated = keyTranslator.translate(phraseKey) ?? phraseKey
                translatedOptions[key] = translated
            }
            if translatedOptions.isNotEmpty && formField.isSelectOption {
                translatedOptions[""] = ""
            }
            return FormFieldNode.make(
                formField: formField,
                children: children,
                options: translatedOptions
            )
        }

        return buildNode("", "").children
    }

    func flatten() -> FormFieldNode {
        let flatChildren = Array(children.map { child in
            [[child], child.children].joined()
        }.joined())
        return copy { $0.children = flatChildren }
    }
}

let EmptyIncidentFormField = IncidentFormField(
    label: "",
    htmlType: "",
    group: "",
    help: "",
    placeholder: "",
    validation: "",
    valuesDefault: nil,
    values: [String : String](),
    isCheckboxDefaultTrue: false,
    recurDefault: "",
    isRequired: false,
    isReadOnly: false,
    isReadOnlyBreakGlass: false,
    labelOrder: 0,
    listOrder: 0,
    isInvalidated: false,
    fieldKey: "",
    parentKey: "",
    selectToggleWorkType: ""
)

let EmptyFormFieldNode = FormFieldNode.make(
    formField: EmptyIncidentFormField,
    children: [],
    options: [:]
)
