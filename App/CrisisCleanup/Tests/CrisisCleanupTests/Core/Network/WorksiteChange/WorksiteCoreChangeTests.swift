import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteCoreChangeTests: XCTestCase {
    private let minDefinedWorksite = NetworkWorksiteFull(
        id: 42,
        address: "address-min",
        autoContactFrequencyT: "auto-frequency-min",
        caseNumber: "case-min",
        city: "city-min",
        county: "county-min",
        email: nil,
        events: [],
        favorite: NetworkType(id: 38, typeT: "", createdAt: ChangeTestUtil.createdAtA),
        files: [],
        flags: [],
        formData: [],
        incident: 486,
        keyWorkType: NetworkWorkType(
            id: 454,
            createdAt: ChangeTestUtil.createdAtA,
            orgClaim: nil,
            nextRecurAt: nil,
            phase: nil,
            recur: nil,
            status: "status-min",
            workType: "work-type-min"
        ),
        location: NetworkWorksiteFull.Location(type: "Point", coordinates: [5141.3, 51341.4]),
        name: "name-min",
        notes: [],
        phone1: "phone-min",
        phone2: nil,
        plusCode: nil,
        postalCode: "postal-min",
        reportedBy: nil,
        state: "state-min",
        svi: nil,
        updatedAt: ChangeTestUtil.updatedAtA,
        what3words: nil,
        workTypes: [
            NetworkWorkType(
                id: 454,
                createdAt: ChangeTestUtil.createdAtA,
                orgClaim: nil,
                nextRecurAt: nil,
                phase: nil,
                recur: nil,
                status: "status-min",
                workType: "work-type-min"
            )
        ]
    )
    private let fullyDefinedWorksite = NetworkWorksiteFull(
        id: 67,
        address: "address",
        autoContactFrequencyT: "auto-frequency",
        caseNumber: "case",
        city: "city",
        county: "county",
        email: "email",
        events: [
            NetworkEvent(
                id: 643,
                attr: [:],
                createdAt: ChangeTestUtil.createdAtA,
                createdBy: 853,
                eventKey: "key",
                patientId: 9684,
                patientModel: "patient",
                event: NetworkEvent.Description(eventKey: "key", eventDescriptionT: "description", eventNameT: "name")
            ),
        ],
        favorite: NetworkType(id: 38, typeT: "favorite", createdAt: ChangeTestUtil.createdAtA),
        files: [],
        flags: [
            NetworkFlag(id: 53853, action: "action", createdAt: ChangeTestUtil.createdAtA, isHighPriority: false, notes: "notes", reasonT: "reason", requestedAction: nil)
        ],
        formData: [
            KeyDynamicValuePair("key", DynamicValue("dynamic-value"))
        ],
        incident: 875,
        keyWorkType: NetworkWorkType(
            id: 5498,
            createdAt: ChangeTestUtil.createdAtB,
            orgClaim: nil,
            nextRecurAt: nil,
            phase: nil,
            recur: nil,
            status: "status-b",
            workType: "work-type-b"
        ),
        location: NetworkWorksiteFull.Location(type: "Point", coordinates: [-534.53513, 534.1353]),
        name: "name",
        notes: [
            NetworkNote(4845, ChangeTestUtil.createdAtA, false, "note"),
        ],
        phone1: "phone",
        phone2: "phone-2",
        plusCode: "plus-code",
        postalCode: "postal-code",
        reportedBy: 683,
        state: "state",
        svi: 0.5,
        updatedAt: ChangeTestUtil.updatedAtA,
        what3words: "what-three-words",
        workTypes: [
            NetworkWorkType(
                id: 95,
                createdAt: ChangeTestUtil.createdAtA,
                orgClaim: nil,
                nextRecurAt: nil,
                phase: nil,
                recur: nil,
                status: "status-a",
                workType: "work-type-a"
            ),
            NetworkWorkType(
                id: 5498,
                createdAt: ChangeTestUtil.createdAtB,
                orgClaim: nil,
                nextRecurAt: nil,
                phase: nil,
                recur: nil,
                status: "status-b",
                workType: "work-type-b"
            ),
        ]
    )

    private let baseSnapshot = testCoreSnapshot(
        address: "address-snapshot",
        autoContactFrequencyT: "frequency-snapshot",
        caseNumber: "case-snapshot",
        city: "city-snapshot",
        county: "county-snapshot",
        createdAt: ChangeTestUtil.createdAtA,
        email: "email-snapshot",
        incidentId: 75,
        latitude: -85.3523,
        longitude: -23.38,
        name: "name-snapshot",
        phone1: "phone-snapshot",
        postalCode: "postal-snapshot",
        reportedBy: 83,
        state: "state-snapshot",
        updatedAt: ChangeTestUtil.updatedAtA
    )

    func testNoChanges() {
        let actualMin = minDefinedWorksite.getCoreChange(
            baseSnapshot,
            baseSnapshot,
            [],
            nil,
            baseSnapshot.updatedAt!
        )
        XCTAssertNil(actualMin)

        let actualFull = fullyDefinedWorksite.getCoreChange(
            baseSnapshot,
            baseSnapshot.copy { $0.updatedAt = ChangeTestUtil.updatedAtB },
            [],
            nil,
            baseSnapshot.updatedAt!
        )
        XCTAssertNil(actualFull)
    }

    func testSingleChange() {
        let changeSnapshot = baseSnapshot.copy { $0.address = "address-updated" }

        let actual = fullyDefinedWorksite.getCoreChange(
            baseSnapshot,
            changeSnapshot,
            [],
            nil,
            changeSnapshot.updatedAt!
        )

        let expected = NetworkWorksitePush(
            id: fullyDefinedWorksite.id,
            address: changeSnapshot.address,
            autoContactFrequencyT: fullyDefinedWorksite.autoContactFrequencyT,
            caseNumber: fullyDefinedWorksite.caseNumber,
            city: fullyDefinedWorksite.city,
            county: fullyDefinedWorksite.county,
            email: fullyDefinedWorksite.email,
            favorite: fullyDefinedWorksite.favorite,
            formData: [],
            incident: fullyDefinedWorksite.incident,
            keyWorkType: nil,
            location: fullyDefinedWorksite.location,
            name: fullyDefinedWorksite.name,
            phone1: fullyDefinedWorksite.phone1,
            phone2: fullyDefinedWorksite.phone2,
            plusCode: fullyDefinedWorksite.plusCode,
            postalCode: fullyDefinedWorksite.postalCode,
            reportedBy: fullyDefinedWorksite.reportedBy,
            state: fullyDefinedWorksite.state,
            svi: fullyDefinedWorksite.svi,
            updatedAt: fullyDefinedWorksite.updatedAt,
            what3words: fullyDefinedWorksite.what3words,
            workTypes: [],

            skipDuplicateCheck: true,
            sendSms: nil
        )
        XCTAssertEqual(expected, actual)
    }

    func testMinChanges() {
        let changeSnapshot = testCoreSnapshot(
            address: "address-change",
            autoContactFrequencyT: "frequency-change",
            caseNumber: "case-change",
            city: "city-change",
            county: "county-change",
            createdAt: ChangeTestUtil.createdAtB,
            email: "email-change",
            incidentId: 64,
            latitude: 64.84,
            longitude: 56.458,
            name: "name-change",
            phone1: "phone-change",
            postalCode: "postal-change",
            reportedBy: 151,
            state: "state-change",
            updatedAt: ChangeTestUtil.updatedAtB
        )
        let actual = fullyDefinedWorksite.getCoreChange(
            baseSnapshot,
            changeSnapshot,
            [],
            nil,
            changeSnapshot.updatedAt!
        )

        let expected = NetworkWorksitePush(
            id: fullyDefinedWorksite.id,
            address: changeSnapshot.address,
            autoContactFrequencyT: changeSnapshot.autoContactFrequencyT,
            caseNumber: fullyDefinedWorksite.caseNumber,
            city: changeSnapshot.city,
            county: changeSnapshot.county,
            email: changeSnapshot.email,
            favorite: fullyDefinedWorksite.favorite,
            formData: [],
            incident: changeSnapshot.incidentId,
            keyWorkType: nil,
            location: NetworkWorksiteFull.Location(
                type: "Point",
                coordinates: [changeSnapshot.longitude, changeSnapshot.latitude]
            ),
            name: changeSnapshot.name,
            phone1: changeSnapshot.phone1,
            phone2: fullyDefinedWorksite.phone2,
            plusCode: fullyDefinedWorksite.plusCode,
            postalCode: changeSnapshot.postalCode,
            reportedBy: fullyDefinedWorksite.reportedBy,
            state: changeSnapshot.state,
            svi: fullyDefinedWorksite.svi,
            updatedAt: changeSnapshot.updatedAt!,
            what3words: fullyDefinedWorksite.what3words,
            workTypes: [],

            skipDuplicateCheck: true,
            sendSms: nil
        )
        XCTAssertEqual(expected, actual)
    }

    func testFullChanges() {
        let changeSnapshot = testCoreSnapshot(
            address: "address-change",
            autoContactFrequencyT: "frequency-change",
            caseNumber: "case-change",
            city: "city-change",
            county: "county-change",
            createdAt: ChangeTestUtil.createdAtB,
            email: "email-change",
            favoriteId: 523,
            formData: ["a": DynamicValue("a-value")],
            incidentId: 75,
            keyWorkTypeId: 835,
            latitude: 64.84,
            longitude: 56.458,
            name: "name-change",
            networkId: 85014,
            phone1: "phone-change",
            phone2: "phone-2-change",
            plusCode: "plus-code-change",
            postalCode: "postal-change",
            reportedBy: 151,
            state: "state-change",
            svi: 0.3,
            updatedAt: ChangeTestUtil.updatedAtB,
            what3Words: "what-3-words-change",
            isAssignedToOrgMember: true
        )
        let actual = fullyDefinedWorksite.getCoreChange(
            baseSnapshot,
            changeSnapshot,
            [],
            nil,
            changeSnapshot.updatedAt!
        )

        let expected = NetworkWorksitePush(
            id: fullyDefinedWorksite.id,
            address: changeSnapshot.address,
            autoContactFrequencyT: changeSnapshot.autoContactFrequencyT,
            caseNumber: fullyDefinedWorksite.caseNumber,
            city: changeSnapshot.city,
            county: changeSnapshot.county,
            email: changeSnapshot.email,
            favorite: fullyDefinedWorksite.favorite,
            formData: [],
            incident: fullyDefinedWorksite.incident,
            keyWorkType: nil,
            location: NetworkWorksiteFull.Location(
                type: "Point",
                coordinates: [changeSnapshot.longitude, changeSnapshot.latitude]
            ),
            name: changeSnapshot.name,
            phone1: changeSnapshot.phone1,
            phone2: changeSnapshot.phone2,
            plusCode: changeSnapshot.plusCode,
            postalCode: changeSnapshot.postalCode,
            reportedBy: fullyDefinedWorksite.reportedBy,
            state: changeSnapshot.state,
            svi: fullyDefinedWorksite.svi,
            updatedAt: changeSnapshot.updatedAt!,
            what3words: changeSnapshot.what3Words,
            workTypes: [],

            skipDuplicateCheck: true,
            sendSms: nil
        )
        XCTAssertEqual(expected, actual)
    }
}
