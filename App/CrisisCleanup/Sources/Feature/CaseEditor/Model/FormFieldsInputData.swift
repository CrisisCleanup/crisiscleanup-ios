struct FormFieldsInputData {
    let managedGroups: Set<String>
    let binaryFields: Set<String>
    let contentFields: [String: String]
    let groupFormFieldData: [String: [FieldDynamicValue]]
    let groupFields: [String: [FieldDynamicValue]]

    init(
        managedGroups: Set<String> = [],
        binaryFields: Set<String> = [],
        contentFields: [String : String] = [:],
        groupFormFieldData: [String : [FieldDynamicValue]] = [:],
        groupFields: [String : [FieldDynamicValue]] = [:]
    ) {
        self.managedGroups = managedGroups
        self.binaryFields = binaryFields
        self.contentFields = contentFields
        self.groupFormFieldData = groupFormFieldData
        self.groupFields = groupFields
    }
}

private let formFieldGroupKeys = [
    DetailsFormGroupKey,
    WorkFormGroupKey,
    HazardsFormGroupKey,
    VolunteerReportFormGroupKey,
]

let ignoreFormFieldKeys = Set(["cross_street", "email"])

internal func loadFormFieldsInputData(_ worksiteProvider: EditableWorksiteProvider) -> FormFieldsInputData {
    let worksite = worksiteProvider.editableWorksite.value

    let workTypeMap = worksite.workTypes.associateBy { $0.workTypeLiteral }

    var managedGroups: Set<String> = []
    var groupFormFieldData: [String: [FieldDynamicValue]] = [:]
    var groupFields = [String: [FieldDynamicValue]]()
    var binaryFields: Set<String> = []
    var contentFields = [String: String]()
    for groupKey in formFieldGroupKeys {
        let groupNode = worksiteProvider.getGroupNode(groupKey)
        let autoManageGroups = groupKey == DetailsFormGroupKey
        let isWorkInputData = groupKey == WorkFormGroupKey
        let worksiteFormData = worksite.formData ?? [:]
        let formFieldData = groupNode.children
            .filter { !ignoreFormFieldKeys.contains($0.fieldKey) }
            .map { node in
                var dynamicValue = DynamicValue("")
                if let formValue = worksiteFormData[node.fieldKey] {
                    dynamicValue = DynamicValue(
                        valueString: formValue.valueString,
                        isBool: formValue.isBoolean,
                        valueBool: formValue.valueBoolean
                    )
                }

                let isActiveGroup = autoManageGroups &&
                node.children.isNotEmpty &&
                node.children.first(where: { child in
                    let childFormValue = worksiteFormData[child.fieldKey]
                    return childFormValue?.hasValue == true
                }) != nil
                if isActiveGroup && !dynamicValue.isBoolTrue {
                    managedGroups.insert(node.fieldKey)
                    dynamicValue = DynamicValue(true)
                }

                var fieldData = FieldDynamicValue(
                    node.formField,
                    node.options,
                    childKeys: Set(node.children.map { $0.fieldKey }),
                    nestLevel: node.parentKey == groupNode.fieldKey ? 0 : 1,
                    dynamicValue: dynamicValue
                )

                if isWorkInputData && fieldData.isWorkTypeGroup {
                    let fieldWorkType = node.formField.selectToggleWorkType
                    let status = workTypeMap[fieldWorkType]?.status
                    fieldData = fieldData.copy {
                        $0.workTypeStatus = status ?? .openUnassigned
                    }
                }

                if dynamicValue.isBool {
                    if dynamicValue.valueBool {
                        binaryFields.insert(node.fieldKey)
                    }
                } else {
                    if dynamicValue.valueString.isNotBlank {
                        contentFields[node.fieldKey] = dynamicValue.valueString
                    }
                }

                return fieldData
            }

        groupFormFieldData[groupKey] = formFieldData
        groupFields[groupKey] = formFieldData.filter { $0.childrenCount > 0 }
    }

    return FormFieldsInputData(
        managedGroups: managedGroups,
        binaryFields: binaryFields,
        contentFields: contentFields,
        groupFormFieldData: groupFormFieldData,
        groupFields: groupFields
    )
}
