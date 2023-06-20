import Foundation

extension NetworkIncident {
    var asRecord: IncidentRecord {
        IncidentRecord(
            id: id,
            startAt: startAt,
            name: name,
            shortName: shortName,
            type: type,
            activePhoneNumber: activePhoneNumber?.commaJoined,
            turnOnRelease: turnOnRelease,
            isArchived: isArchived ?? false
        )
    }

    var asLocationRecords: [IncidentLocationRecord] {
        locations.map { IncidentLocationRecord(id: $0.id, location: $0.location) }
    }

    var asIncidentToLocationRecords: [IncidentToIncidentLocationRecord] {
        locations.map { IncidentToIncidentLocationRecord(id: id, incidentLocationId: $0.id) }
    }
}

extension NetworkIncidentFormField {
    func asRecord(_ incidentId: Int64) throws -> IncidentFormFieldRecord {
        let jsonEncoder = JSONEncoder()
        var valuesMap = [String:String]()
        if let valuesNn = values {
            valuesMap = valuesNn
                .filter { $0.value?.isNotBlank == true }
                .reduce(valuesMap, { acc, curr in
                    var acc = acc
                    acc[curr.value!] = curr.name
                    return acc
                })
        }

        let valuesJson = valuesMap.isEmpty ? nil : try jsonEncoder.encodeToString(valuesMap)
        let isDefaultVaulesSensible = valuesJson == nil &&
        valuesDefault?.isNotEmpty == true &&
        !isCheckboxDefaultTrue
        let valuesDefaultJson = isDefaultVaulesSensible ? try jsonEncoder.encodeToString(valuesDefault) : nil
        return IncidentFormFieldRecord(
            id: nil,
            incidentId: incidentId,
            parentKey: fieldParentKey ?? "",
            fieldKey: fieldKey,
            label: label,
            htmlType: htmlType,
            dataGroup: dataGroup,
            help: help,
            placeholder: placeholder,
            readOnlyBreakGlass: readOnlyBreakGlass,
            valuesDefaultJson: valuesDefaultJson,
            isCheckboxDefaultTrue: isCheckboxDefaultTrue,
            orderLabel: orderLabel ?? -1,
            validation: validation,
            recurDefault: recurDefault,
            valuesJson: valuesJson,
            isRequired: isRequired,
            isReadOnly: isReadOnly,
            listOrder: listOrder,
            isInvalidated: invalidatedAt != nil,
            selectToggleWorkType: selectToggleWorkType
        )
    }
}
