import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

internal let incidentA = IncidentRecord(
    id: 152,
    startAt: Date().addingTimeInterval(-1.days),
    name: "Apricot",
    shortName: "Hurricane Apri",
    caseLabel: "T",
    type: "hurricane",
    activePhoneNumber: nil,
    turnOnRelease: true,
    isArchived: false
)
internal let incidentB = IncidentRecord(
    id: 987,
    startAt: Date().addingTimeInterval(-1.hours),
    name: "Berry",
    shortName: "Tornado Ber",
    caseLabel: "i5",
    type: "tornado",
    activePhoneNumber: nil,
    turnOnRelease: false,
    isArchived: false
)
internal let incidentLocationA = IncidentLocationRecord(id: 345, location: 456)
internal let incidentLocationB = IncidentLocationRecord(id: 864, location: 98)
internal let incidentLocationC = IncidentLocationRecord(id: 78, location: 843)
internal let incidentLocationXrA = IncidentToIncidentLocationRecord(
    id: incidentA.id,
    incidentLocationId: incidentLocationA.id
)
internal let incidentLocationXrB = IncidentToIncidentLocationRecord(
    id: incidentA.id,
    incidentLocationId: incidentLocationB.id
)
internal let incidentLocationXrC = IncidentToIncidentLocationRecord(
    id: incidentB.id,
    incidentLocationId: incidentLocationC.id
)

class IncidentDaoTests: XCTestCase {
    func testSaveIncidents() async throws {
        let (_, appDb) = try initializeTestDb()
        let incidentDao = IncidentDao(appDb)

        try await incidentDao.saveIncidents(
            [incidentA],
            [incidentLocationA, incidentLocationB],
            [incidentLocationXrA, incidentLocationXrB]
        )

        incidentDao.streamIncidents()
            .collect(1)
            .expect({ values in
                values[0].forEach { incident in
                    XCTAssertEqual(
                        testIncident(
                            152,
                            "Apricot",
                            "Hurricane Apri",
                            "T",
                            "hurricane",
                            locationIds: [456, 98],
                            turnOnRelease: true
                        ),
                        incident
                    )
                }
            })
            .expectNoCompletion()
            .waitForExpectations(timeout: 0.1)

        let incidentAChange = incidentA.copy {
            $0.shortName = "Hur A"
            $0.activePhoneNumber = "active-phone"
        }
        let locationBChange = IncidentLocationRecord(id: 87, location: 145)
        let xrBChange = IncidentToIncidentLocationRecord(id: incidentA.id, incidentLocationId: locationBChange.id)

        try await incidentDao.saveIncidents(
            [incidentB, incidentAChange],
            [incidentLocationC, locationBChange],
            [xrBChange, incidentLocationXrC]
        )
        incidentDao.streamIncidents()
            .collect(1)
            .expect([[
                testIncident(
                    987,
                    "Berry",
                    "Tornado Ber",
                    "i5",
                    "tornado",
                    locationIds: [843]
                ),
                testIncident(
                    152,
                    "Apricot",
                    "Hur A",
                    "T",
                    "hurricane",
                    locationIds: [145],
                    activePhoneNumbers: ["active-phone"],
                    turnOnRelease: true
                )
            ]])
            .waitForExpectations(timeout: 0.1)

        let incidentAArchive = incidentA.copy {
            $0.isArchived = true
        }
        let incidentBChange = incidentB.copy {
            $0.turnOnRelease = true
        }
        try await incidentDao.saveIncidents(
            [incidentBChange, incidentAArchive],
            [incidentLocationC, locationBChange],
            [incidentLocationXrC]
        )
        incidentDao.streamIncidents()
            .collect(1)
            .expect([[
                testIncident(
                    987,
                    "Berry",
                    "Tornado Ber",
                    "i5",
                    "tornado",
                    locationIds: [843],
                    turnOnRelease: true
                )
            ]])
            .waitForExpectations(timeout: 0.1)
    }

    func testUpdateFormFields() async throws {
        let (_, appDb) = try initializeTestDb()
        let incidentDao = IncidentDao(appDb)

        try await incidentDao.saveIncidents(
            [incidentA],
            [incidentLocationA],
            [incidentLocationXrA]
        )

        let incidentId = incidentA.id
        try await incidentDao.updateFormFields([
            (incidentId, [
                testIncidentFormFieldRecord(incidentId, "field-a"),
                testIncidentFormFieldRecord(incidentId, "field-b"),
                testIncidentFormFieldRecord(
                    incidentId,
                    "field-c",
                    help: "help",
                    placeholder: "placeholder",
                    readOnlyBreakGlass: true,
                    valuesDefaultJson: #"{"values": "default"}"#,
                    isCheckboxDefaultTrue: false,
                    orderLabel: 5,
                    validation: "validation",
                    recurDefault: "recur-default",
                    valuesJson: #"{"values": "json"}"#,
                    isRequired: true,
                    isReadOnly: false,
                    listOrder: 45,
                    isInvalidated: false,
                    selectToggleWorkType: "toggle-work-type"
                ),
            ])
        ])

        incidentDao.streamFormFieldsIncident(incidentId)
            .collect(1)
            .expect([
                testIncident(
                    incidentId,
                    incidentA.name,
                    incidentA.shortName,
                    incidentA.caseLabel,
                    incidentA.type,
                    locationIds: [456],
                    formFields: [
                        testIncidentFormField(incidentId, "field-a"),
                        testIncidentFormField(incidentId, "field-b"),
                        testIncidentFormField(
                            incidentId,
                            "field-c",
                            help: "help",
                            placeholder: "placeholder",
                            valuesDefault: [:],
                            isCheckboxDefaultTrue: false,
                            isRequired: true,
                            isReadOnly: false,
                            isReadOnlyBreakGlass: true,
                            labelOrder: 5,
                            listOrder: 45,
                            validation: "validation",
                            recurDefault: "recur-default",
                            values: ["values": "json"],
                            isInvalidated: false,
                            selectToggleWorkType: "toggle-work-type"
                        ),
                    ],
                    turnOnRelease: true
                ),
            ])
            .waitForExpectations(timeout: 0.1)

        try await incidentDao.updateFormFields([
            (incidentId, [
                testIncidentFormFieldRecord(incidentId, "field-b", isInvalidated: true),
                testIncidentFormFieldRecord(incidentId, "field-c"),
                testIncidentFormFieldRecord(
                    incidentId,
                    "field-a",
                    help: "help",
                    placeholder: "placeholder",
                    readOnlyBreakGlass: true,
                    valuesDefaultJson: #"{"values": "default"}"#,
                    isCheckboxDefaultTrue: false,
                    orderLabel: 5,
                    validation: "validation",
                    recurDefault: "recur-default",
                    valuesJson: "",
                    isRequired: true,
                    isReadOnly: false,
                    listOrder: 45,
                    isInvalidated: false,
                    selectToggleWorkType: "toggle-work-type"
                ),
            ])
        ])

        incidentDao.streamFormFieldsIncident(incidentId)
            .collect(1)
            .expect([
                testIncident(
                    incidentId,
                    incidentA.name,
                    incidentA.shortName,
                    incidentA.caseLabel,
                    incidentA.type,
                    locationIds: [456],
                    formFields: [
                        testIncidentFormField(incidentId, "field-c"),
                        testIncidentFormField(
                            incidentId,
                            "field-a",
                            help: "help",
                            placeholder: "placeholder",
                            valuesDefault: ["values": "default"],
                            isCheckboxDefaultTrue: false,
                            isRequired: true,
                            isReadOnly: false,
                            isReadOnlyBreakGlass: true,
                            labelOrder: 5,
                            listOrder: 45,
                            validation: "validation",
                            recurDefault: "recur-default",
                            values: [:],
                            isInvalidated: false,
                            selectToggleWorkType: "toggle-work-type"
                        ),
                    ],
                    turnOnRelease: true
                ),
            ])
            .waitForExpectations(timeout: 0.1)
    }
}

internal func testIncident(
    _ id: Int64,
    _ name: String,
    _ shortName: String,
    _ caseLabel: String,
    _ disasterLiteral: String,
    locationIds: [Int64] = [],
    activePhoneNumbers: [String] = [],
    formFields: [IncidentFormField] = [],
    turnOnRelease: Bool = false
) -> Incident {
    return Incident(
        id: id,
        name: name,
        shortName: shortName,
        caseLabel: caseLabel,
        locationIds: locationIds,
        activePhoneNumbers: activePhoneNumbers,
        formFields: formFields,
        turnOnRelease: turnOnRelease,
        disasterLiteral: disasterLiteral
    )
}

internal func testIncidentFormFieldRecord(
    _ incidentId: Int64,
    _ fieldKey: String,
    parentKey: String = "parent-key",
    label: String = "label",
    dataGroup: String = "group",
    htmlType: String = "html-type",
    help: String? = nil,
    placeholder: String? = nil,
    readOnlyBreakGlass: Bool = false,
    valuesDefaultJson: String? = nil,
    isCheckboxDefaultTrue: Bool? = nil,
    orderLabel: Int = 0,
    validation: String? = nil,
    recurDefault: String? = nil,
    valuesJson: String? = nil,
    isRequired: Bool? = nil,
    isReadOnly: Bool? = nil,
    listOrder: Int = 0,
    isInvalidated: Bool = false,
    selectToggleWorkType: String? = nil,
    id: Int64? = nil
) -> IncidentFormFieldRecord {
    return IncidentFormFieldRecord(
        id: id,
        incidentId: incidentId,
        parentKey: parentKey,
        fieldKey: fieldKey,
        label: label,
        htmlType: htmlType,
        dataGroup: dataGroup,
        help: help,
        placeholder: placeholder,
        readOnlyBreakGlass: readOnlyBreakGlass,
        valuesDefaultJson: valuesDefaultJson,
        isCheckboxDefaultTrue: isCheckboxDefaultTrue,
        orderLabel: orderLabel,
        validation: validation,
        recurDefault: recurDefault,
        valuesJson: valuesJson,
        isRequired: isRequired,
        isReadOnly: isReadOnly,
        listOrder: listOrder,
        isInvalidated: isInvalidated,
        selectToggleWorkType: selectToggleWorkType
    )
}

internal func testIncidentFormField(
    _ incidentId: Int64,
    _ fieldKey: String,
    parentKey: String = "parent-key",
    label: String = "label",
    group: String = "group",
    htmlType: String = "html-type",
    help: String = "",
    placeholder: String = "",
    valuesDefault: [String:String?]? = [:],
    isCheckboxDefaultTrue: Bool = false,
    isRequired: Bool = false,
    isReadOnly: Bool = false,
    isReadOnlyBreakGlass: Bool = false,
    labelOrder: Int = 0,
    listOrder: Int = 0,
    validation: String = "",
    recurDefault: String = "",
    values: [String:String] = [:],
    isInvalidated: Bool = false,
    selectToggleWorkType: String = ""
) -> IncidentFormField {
    return IncidentFormField(
        label: label,
        htmlType: htmlType,
        group: group,
        help: help,
        placeholder: placeholder,
        validation: validation,
        valuesDefault: valuesDefault,
        values: values,
        isCheckboxDefaultTrue: isCheckboxDefaultTrue,
        recurDefault: recurDefault,
        isRequired: isRequired,
        isReadOnly: isReadOnly,
        isReadOnlyBreakGlass: isReadOnlyBreakGlass,
        labelOrder: labelOrder,
        listOrder: listOrder,
        isInvalidated: isInvalidated,
        fieldKey: fieldKey,
        parentKey: parentKey,
        selectToggleWorkType: selectToggleWorkType
    )
}
