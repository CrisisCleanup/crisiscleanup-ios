import XCTest
@testable import CrisisCleanup

final class SaveWorksiteUpdateWorkTypeTests: XCTestCase {
    func testCopyModifiedFlag_noChange() {
        let flagsWorksite = testWorksite(
            flags: [
                WorksiteFlag.flag(flag: .duplicate)
            ]
        )

        let noChangeCopyMissing = flagsWorksite.copyModifiedFlag(
            false, { _ in false }, WorksiteFlag.highPriority
        )
        XCTAssertEqual(flagsWorksite, noChangeCopyMissing)

        let noChangeCopyExists = flagsWorksite.copyModifiedFlag(
            true, { _ in true }, WorksiteFlag.highPriority
        )
        XCTAssertEqual(flagsWorksite, noChangeCopyExists)
    }

    func testCopyModifiedFlag_changes() {
        let flagsWorksite = testWorksite()

        // Removing flag not in flags does not fail
        let removeNonExisting = flagsWorksite.copyModifiedFlag(
            false, { _ in true }, WorksiteFlag.highPriority
        )
        XCTAssertEqual(flagsWorksite, removeNonExisting)

        // Add a few flags
        let addFlagsWorksite = flagsWorksite
            .copyModifiedFlag(
                true, { _ in false }, WorksiteFlag.highPriority
            )
            .copyModifiedFlag(
                true, { _ in false }, WorksiteFlag.wrongLocation
            )
            .copyModifiedFlag(
                true, { _ in false }, {
                    WorksiteFlag.flag(
                        flag: .markForDeletion,
                        notes: "delete-notes",
                        requestedAction: "delete-action"
                    )
                }
            )

        let expectedAddFlags = flagsWorksite.copy {
            $0.flags = [
                WorksiteFlag.highPriority(),
                WorksiteFlag.wrongLocation(),
                WorksiteFlag.flag(
                    flag: .markForDeletion,
                    notes: "delete-notes",
                    requestedAction: "delete-action"
                ),
            ]
        }

        XCTAssertEqual(
            expectedAddFlags.equalizeCreatedAt,
            addFlagsWorksite.equalizeCreatedAt
        )

        // Remove flag(s)
        let removeFlagsWorksite = addFlagsWorksite
            .copyModifiedFlag(
                false, { $0.isHighPriority || $0.isHighPriorityFlag }, { WorksiteFlag.highPriority() }
            )
            .copyModifiedFlag(
                false, { $0.flagType == .upsetClient }, { WorksiteFlag.flag(flag: .upsetClient) }
            )
            .copyModifiedFlag(
                false, { $0.flagType == .markForDeletion }, { WorksiteFlag.flag(flag: .markForDeletion) }
            )

        let expectedRemoveFlags = flagsWorksite.copy {
            $0.flags = [
                WorksiteFlag.wrongLocation(),
            ]
        }

        XCTAssertEqual(
            expectedRemoveFlags.equalizeCreatedAt,
            removeFlagsWorksite.equalizeCreatedAt
        )
    }

    // MARK: Work types

    // TODO: Frequency work types

    private let workTypeLookup = ["tarps_needed": "tarp", "mold_scraping": "mold_remediation", "mold_remediation_info": "mold_remediation", "floors_affected": "muck_out", "mold_hvac": "mold_remediation", "house_roof_damage": "tarp", "needs_visual": "rebuild", "roof_type": "tarp", "roof_pitch": "tarp", "outbuilding_roof_damage": "tarp", "flood_height_select": "muck_out", "tile_removal": "muck_out", "appliance_removal": "muck_out", "debris_description": "debris", "mold_drying": "mold_remediation", "mold_replace_studs": "mold_remediation", "carpet_removal": "muck_out", "nonvegitative_debris_removal": "debris", "vegitative_debris_removal": "debris", "mold_amount": "mold_remediation", "ceiling_water_damage": "muck_out", "rebuild_details": "rebuild", "heavy_machinary_required": "debris", "rebuild_info": "rebuild", "notes": "mold_remediation", "drywall_removal": "muck_out", "help_install_tarp": "tarp", "muck_out_info": "muck_out", "tarping_info": "tarp", "unsalvageable_structure": "debris", "debris_info": "debris", "mold_spraying": "mold_remediation", "heavy_item_removal": "muck_out", "tree_info": "trees", "num_wide_trees": "trees", "num_trees_down": "trees", "interior_debris_removal": "debris", "hardwood_floor_removal": "muck_out"]

    private let formFieldLookup = [
        "needs_visual": testFormField("workInfo", "needs_visual", "rebuild_info", selectToggleWorkType: "rebuild"),
        "claim_status_report_info": testFormField("caseInfo", "claim_status_report_info", ""),
        "nonvegitative_debris_removal": testFormField("workInfo", "nonvegitative_debris_removal", "debris_info", selectToggleWorkType: "debris"),
        "ceiling_water_damage": testFormField("workInfo", "ceiling_water_damage", "muck_out_info", selectToggleWorkType: "muck_out"),
        "vegitative_debris_removal": testFormField("workInfo", "vegitative_debris_removal", "debris_info", selectToggleWorkType: "debris"),
        "debris_description": testFormField("workInfo", "debris_description", "debris_info", selectToggleWorkType: "debris"),
        "heavy_item_removal": testFormField("workInfo", "heavy_item_removal", "muck_out_info", selectToggleWorkType: "muck_out"),
        "drywall_removal": testFormField("workInfo", "drywall_removal", "muck_out_info", selectToggleWorkType: "muck_out"),
        "power_status": testFormField("workInfo", "power_status", "utilities_info"),
        "tarping_info": testFormField("workInfo", "tarping_info", "work_info", selectToggleWorkType: "tarp"),
        "habitable": testFormField("caseInfo", "habitable", "hazards_info"),
        "mold_spraying": testFormField("workInfo", "mold_spraying", "mold_remediation_info", selectToggleWorkType: "mold_remediation"),
        "house_roof_damage": testFormField("workInfo", "house_roof_damage", "tarping_info", selectToggleWorkType: "tarp"),
        "carpet_removal": testFormField("workInfo", "carpet_removal", "muck_out_info", selectToggleWorkType: "muck_out"),
        "residence_type": testFormField("caseInfo", "residence_type", "property_info"),
        "mold_amount": testFormField("workInfo", "mold_amount", "mold_remediation_info", selectToggleWorkType: "mold_remediation"),
        "num_trees_down": testFormField("workInfo", "num_trees_down", "tree_info", selectToggleWorkType: "trees"),
        "gas_status": testFormField("workInfo", "gas_status", "utilities_info"),
        "work_info": testFormField("workInfo", "work_info", ""),
        "heavy_machinary_required": testFormField("workInfo", "heavy_machinary_required", "debris_info", selectToggleWorkType: "debris"),
        "interior_debris_removal": testFormField("workInfo", "interior_debris_removal", "debris_info", selectToggleWorkType: "debris"),
        "veteran": testFormField("personalInfo", "veteran", "property_info"),
        "tarps_needed": testFormField("workInfo", "tarps_needed", "tarping_info", selectToggleWorkType: "tarp"),
        "tree_info": testFormField("workInfo", "tree_info", "work_info", selectToggleWorkType: "trees"),
        "debris_info": testFormField("workInfo", "debris_info", "work_info", selectToggleWorkType: "debris"),
        "mold_remediation_info": testFormField("workInfo", "mold_remediation_info", "work_info", selectToggleWorkType: "mold_remediation"),
        "mold_hvac": testFormField("workInfo", "mold_hvac", "mold_remediation_info", selectToggleWorkType: "mold_remediation"),
        "water_status": testFormField("caseInfo", "water_status", "utilities_info"),
        "hazards_info": testFormField("caseInfo", "hazards_info", ""),
        "rebuild_info": testFormField("workInfo", "rebuild_info", "work_info", selectToggleWorkType: "rebuild"),
        "debris_status": testFormField("caseInfo", "debris_status", "claim_status_report_info"),
        "help_install_tarp": testFormField("workInfo", "help_install_tarp", "tarping_info", selectToggleWorkType: "tarp"),
        "hardwood_floor_removal": testFormField("workInfo", "hardwood_floor_removal", "muck_out_info", selectToggleWorkType: "muck_out"),
        "num_stories": testFormField("workInfo", "num_stories", "tarping_info"),
        "muck_out_info": testFormField("workInfo", "muck_out_info", "work_info", selectToggleWorkType: "muck_out"),
        "num_wide_trees": testFormField("workInfo", "num_wide_trees", "tree_info", selectToggleWorkType: "trees"),
        "unsalvageable_structure": testFormField("workInfo", "unsalvageable_structure", "debris_info", selectToggleWorkType: "debris"),
        "tarp_info": testFormField("workInfo", "tarp_info", "work_info", selectToggleWorkType: "tarp"),
        "property_info": testFormField("personalInfo", "property_info", ""),
        "rebuild_details": testFormField("workInfo", "rebuild_details", "rebuild_info", selectToggleWorkType: "rebuild"),
    ]

    // Test variations for work type (with status change where applicable)
    // - Empty work types
    //   - No change
    //   - Add
    // - Existing work types
    //   - No change
    //   - Add
    //   - Remove

    func testNewWorksiteNoWorkTypeFormData() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "property_info": WorksiteFormValue(isBoolean: true),
                    "habitable": worksiteFormValueTrue,
                    "residence_type": WorksiteFormValue(valueString: "residence-type"),
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [:]
            )
        XCTAssertEqual(
            worksite,
            updatedWorksite
        )
    }

    func testNewWorksiteNewWorkTypeFormData() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "mold_remediation_info": WorksiteFormValue(isBoolean: true),
                    "tree_info": worksiteFormValueTrue,
                    "num_trees_down": WorksiteFormValue(valueString: "3"),
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "num_wide_trees": WorksiteFormValue(valueString: "5"),
                    "debris_info": worksiteFormValueTrue,
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [:]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .debris),
                testWorkType(workType: .trees),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testNewWorksiteNewWorkTypeFormDataDifferentStatus() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "mold_remediation_info": WorksiteFormValue(isBoolean: true),
                    "tree_info": worksiteFormValueTrue,
                    "num_trees_down": WorksiteFormValue(valueString: "3"),
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "num_wide_trees": WorksiteFormValue(valueString: "5"),
                    "debris_info": worksiteFormValueTrue,
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                ["trees": .closedDoneByOthers]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .debris),
                testWorkType(workType: .trees, status: .closedDoneByOthers),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteDeleteWorkType() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "mold_remediation_info": WorksiteFormValue(isBoolean: true),
                    "tree_info": worksiteFormValueTrue,
                    "num_trees_down": WorksiteFormValue(valueString: "3"),
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "num_wide_trees": WorksiteFormValue(valueString: "5"),
                    "debris_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .constructionConsultation, status: .closedNoHelpWanted)
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [:]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .debris),
                testWorkType(workType: .trees),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteNoWorkTypeChange() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    // Wouldn't be possible in app. For testing behavior.
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "tarping_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .tarp, status: .openAssigned)
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [:]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .tarp),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteNewWorkTypeFormData() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "tree_info": worksiteFormValueTrue,
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "tarping_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .tarp, status: .openAssigned)
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [:]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .tarp),
                testWorkType(workType: .trees),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteDeleteWorkTypeDifferentStatus() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "mold_remediation_info": WorksiteFormValue(isBoolean: true),
                    "tree_info": worksiteFormValueTrue,
                    "num_trees_down": WorksiteFormValue(valueString: "3"),
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "num_wide_trees": WorksiteFormValue(valueString: "5"),
                    "debris_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .constructionConsultation, status: .closedNoHelpWanted),
                    testWorkType(workType: .debris)
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [
                    "construction_consultation": .closedDoneByOthers,
                    "debris": .openPartiallyCompleted
                ]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .debris, status: .openPartiallyCompleted),
                testWorkType(workType: .trees),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteNoWorkTypeChangeDifferentStatus() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    // Wouldn't be possible in app. For testing behavior.
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "debris_info": worksiteFormValueTrue,
                    "tarping_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .tarp, status: .openAssigned),
                    testWorkType(workType: .debris, status: .closedOutOfScope),
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [
                    "tarp": .closedRejected,
                    "debris": .openNeedsFollowUp,
                ]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .tarp, status: .closedRejected),
                testWorkType(workType: .debris, status: .openNeedsFollowUp),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testExistingWorksiteNewWorkTypeFormDataDifferentStatus() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "tree_info": worksiteFormValueTrue,
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "tarping_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .tarp, status: .openAssigned)
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [
                    "tarp": .closedIncomplete,
                    "trees": .openUnresponsive,
                ]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .tarp, status: .closedIncomplete),
                testWorkType(workType: .trees, status: .openUnresponsive),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }

    func testDeduplicateWorkTypes() {
        let worksite = testWorksite()
            .copy {
                $0.formData = [
                    "debris_info": worksiteFormValueTrue,
                    "tree_info": worksiteFormValueTrue,
                    "vegitative_debris_removal": worksiteFormValueTrue,
                    "tarping_info": worksiteFormValueTrue,
                ]
                $0.workTypes = [
                    testWorkType(workType: .tarp, status: .openAssigned),
                    testWorkType(workType: .moldRemediation, status: .openPartiallyCompleted),
                    testWorkType(workType: .trees, status: .openUnresponsive, id: 84),
                    testWorkType(workType: .tarp, status: .closedDuplicate, id: 55),
                    testWorkType(workType: .trees, status: .closedRejected, id: 11),
                    testWorkType(workType: .trees, status: .openPartiallyCompleted, id: 33),
                ]
            }

        let updatedWorksite = worksite
            .updateWorkTypeStatuses(
                workTypeLookup,
                formFieldLookup,
                [
                    "tarp": .closedIncomplete,
                    "debris": .closedDoneByOthers,
                ]
            )
        let expectedWorksite = worksite.copy {
            $0.workTypes = [
                testWorkType(workType: .tarp, status: .closedIncomplete, id: 55),
                testWorkType(workType: .trees, status: .openUnassigned, id: 84),
                testWorkType(workType: .debris, status: .closedDoneByOthers),
            ]
        }
        XCTAssertEqual(
            expectedWorksite.equalizeCreatedAt,
            updatedWorksite.equalizeCreatedAt
        )
    }
}

private func testWorksite(
    flags: [WorksiteFlag]? = nil,
    formData: [String: WorksiteFormValue]? = nil,
    keyWorkType: WorkType? = nil,
    workTypes: [WorkType] = [],
    id: Int64 = 1,
    incidentId: Int64 = 2,
    networkId: Int64 = 3
) -> Worksite {
    Worksite(
        id: id,
        address: "address",
        autoContactFrequencyT: AutoContactFrequency.none.literal,
        caseNumber: "case-number",
        city: "city",
        county: "county",
        createdAt: nil,
        favoriteId: nil,
        flags: flags,
        formData: formData,
        incidentId: incidentId,
        keyWorkType: keyWorkType,
        latitude: 0.0,
        longitude: 0.0,
        name: "name",
        networkId: networkId,
        phone1: "phone",
        phone1Notes: "phone-notes",
        phone2: "second-phone",
        phone2Notes: "phone2-notes",
        postalCode: "postal-code",
        reportedBy: nil,
        state: "state",
        svi: nil,
        updatedAt: nil,
        workTypes: workTypes
    )
}

private func testWorkType(
    workType: WorkTypeType = .debris,
    status: WorkTypeStatus = .openUnassigned,
    id: Int64 = 0
) -> WorkType {
    WorkType(
        id: id,
        statusLiteral: status.literal,
        workTypeLiteral: workType.id
    )
}

private func testFormField(
    _ group: String,
    _ fieldKey: String,
    _ parentKey: String,
    selectToggleWorkType: String = ""
) -> IncidentFormField {
    IncidentFormField(
        label: "",
        htmlType: "",
        group: group,
        help: "",
        placeholder: "",
        validation: "",
        valuesDefault: nil,
        values: [:],
        isCheckboxDefaultTrue: false,
        recurDefault: "",
        isRequired: false,
        isReadOnly: false,
        isReadOnlyBreakGlass: false,
        labelOrder: 0,
        listOrder: 0,
        isInvalidated: false,
        fieldKey: fieldKey,
        parentKey: parentKey,
        selectToggleWorkType: selectToggleWorkType
    )
}

private let now = Date.now

extension Array where Element == WorksiteFlag {
    fileprivate var equalizeCreatedAt: [WorksiteFlag] {
        map { flag in
            flag.copy { $0.createdAt = now }
        }
    }
}

extension Array where Element == WorkType {
    fileprivate var equalizeCreatedAt: [WorkType] {
        map { workType in
            workType.copy { $0.createdAt = now }
        }
    }
}

extension Worksite {
    fileprivate var equalizeCreatedAt: Worksite {
        copy {
            $0.flags = flags?.equalizeCreatedAt
            $0.workTypes = workTypes.equalizeCreatedAt
        }
    }
}
