import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class NetworkFlagChangeTests: XCTestCase {
    func testNoFlags() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])
        let actualEmpties = noFlagsWorksite.getFlagChanges([], [], [:])
        XCTAssertTrue(actualEmpties.0.isEmpty)
        XCTAssertEqual([], actualEmpties.1)
    }

    func testNoChanges() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])
        let actualNoChange = noFlagsWorksite.getFlagChanges(
            [testFlagSnapshot(3, 32, "reasono")],
            [testFlagSnapshot(3, 32, "reasono")],
            [:]
        )
        XCTAssertTrue(actualNoChange.0.isEmpty)
        XCTAssertEqual([], actualNoChange.1)
    }

    func testAddFlags_noOp() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])

        let emptyStart = [FlagSnapshot]()
        let startOne = [testFlagSnapshot(3, 32, "reasono")]

        // Impossible change to add a networked flag. Do not propagate.
        let actualOne = noFlagsWorksite.getFlagChanges(emptyStart, startOne, [:])
        XCTAssertTrue(actualOne.0.isEmpty)
        XCTAssertEqual([], actualOne.1)
    }

    func testAddFlags_single() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])

        let emptyStart = [FlagSnapshot]()
        let startOne = [testFlagSnapshot(3, -1, "reasono")]

        let actualOneLocal = noFlagsWorksite.getFlagChanges(emptyStart, startOne, [:])
        XCTAssertEqual(
            [(Int64(3), testNetworkFlag(nil, "reasono"))], actualOneLocal.0
        )
        XCTAssertEqual([], actualOneLocal.1)
    }

    func testaddFlags_singleLocalDelta() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])

        let startOne = [testFlagSnapshot(3, 34, "reasono")]
        let addedFlags = [
            testFlagSnapshot(3, 34, "reasono"),
            testFlagSnapshot(4, -1, "newer"),
        ]

        let actualAdd = noFlagsWorksite.getFlagChanges(startOne, addedFlags, [:])
        XCTAssertEqual([(Int64(4), testNetworkFlag(nil, "newer"))], actualAdd.0)
        XCTAssertEqual([], actualAdd.1)
    }

    func testaddFlags_localDeltas() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])

        let startOne = [testFlagSnapshot(3, -1, "reasono")]
        let addedFlags = [
            testFlagSnapshot(3, -1, "reasono"),
            testFlagSnapshot(4, -1, "newer"),
        ]

        // Assume all unmapped local flags are new.
        // This could happen if prior snapshots were skipped/not pushed successfully.
        let actualAddAll = noFlagsWorksite.getFlagChanges(startOne, addedFlags, [:])
        XCTAssertEqual(
            [
                (Int64(3), testNetworkFlag(nil, "reasono")),
                (Int64(4), testNetworkFlag(nil, "newer")),
            ],
            actualAddAll.0
        )
        XCTAssertEqual([], actualAddAll.1)

        // A prior snapshot was successfully pushed and ID mapped.
        let actualAdd = noFlagsWorksite.getFlagChanges(startOne, addedFlags, [3: 43])
        XCTAssertEqual([(Int64(4), testNetworkFlag(nil, "newer"))], actualAdd.0)
        XCTAssertEqual([], actualAdd.1)

        // This could happen when a snapshot was previously synced but
        // never finished normally and ID mappings now exist.
        let actualAddNone = noFlagsWorksite.getFlagChanges(
            startOne,
            addedFlags,
            [3: 43, 4: 46]
        )
        XCTAssertEqual([], actualAddNone.0)
        XCTAssertEqual([], actualAddNone.1)
    }

    func testaddFlags_multiple() {
        let noFlagsWorksite = testNetworkWorksite(flags: [])

        let emptyStart = [FlagSnapshot]()
        let addedFlags = [
            testFlagSnapshot(3, -1, "reasono"),
            testFlagSnapshot(4, -1, "newer"),
        ]

        let actualMultiple = noFlagsWorksite.getFlagChanges(emptyStart, addedFlags, [:])
        XCTAssertEqual(
            [
                (Int64(3), testNetworkFlag(nil, "reasono")),
                (Int64(4), testNetworkFlag(nil, "newer")),
            ],
            actualMultiple.0
        )
        XCTAssertEqual([], actualMultiple.1)
    }

    func testaddFlags_matchingReason() {
        let flagsWorksite = testNetworkWorksite(flags: [testNetworkFlag(Int64(42), "reasono")])

        let emptyStart = [FlagSnapshot]()
        let startOne = [testFlagSnapshot(3, -1, "reasono")]

        let actualIgnore = flagsWorksite.getFlagChanges(emptyStart, startOne, [:])
        XCTAssertTrue(actualIgnore.0.isEmpty)
        XCTAssertTrue(actualIgnore.1.isEmpty)

        let addedFlags = [
            testFlagSnapshot(3, -1, "reasono"),
            testFlagSnapshot(4, -1, "newer"),
        ]
        let actualAdd = flagsWorksite.getFlagChanges(emptyStart, addedFlags, [:])
        XCTAssertEqual([(Int64(4), testNetworkFlag(nil, "newer"))], actualAdd.0)
        XCTAssertTrue(actualAdd.1.isEmpty)

        let flagsWorksiteMultiple = testNetworkWorksite(
            flags: [
                testNetworkFlag(42, "reasono"),
                testNetworkFlag(51, "newer"),
            ]
        )
        let actualNone = flagsWorksiteMultiple.getFlagChanges(emptyStart, addedFlags, [:])
        XCTAssertEqual([], actualNone.0)
        XCTAssertEqual([], actualNone.1)
    }

    private let deleteFlagsWorksite = testNetworkWorksite(
        flags: [
            testNetworkFlag(42, "reasono"),
            testNetworkFlag(51, "newer"),
            testNetworkFlag(487, "pentag"),
        ]
    )

    func testdeleteFlags_none() {
        let actualEmpty = deleteFlagsWorksite.getFlagChanges([], [], [:])
        XCTAssertEqual([], actualEmpty.0)
        XCTAssertEqual([], actualEmpty.1)

        let actualNoChange = deleteFlagsWorksite.getFlagChanges(
            [testFlagSnapshot(3, -1, "reasono")],
            [testFlagSnapshot(13, -1, "reasono")],
            [:]
        )
        XCTAssertEqual([], actualNoChange.0)
        XCTAssertEqual([], actualNoChange.1)
    }

    func testdeleteFlags_noneInExisting() {
        let actualNonExisting = deleteFlagsWorksite.getFlagChanges(
            [testFlagSnapshot(3, -1, "horizo")],
            [],
            [:]
        )
        XCTAssertEqual([], actualNonExisting.0)
        XCTAssertEqual([], actualNonExisting.1)
    }

    func testdeleteFlags() {
        let actualDeleteOne = deleteFlagsWorksite.getFlagChanges(
            [testFlagSnapshot(3, -1, "newer")],
            [],
            [:]
        )
        XCTAssertEqual([], actualDeleteOne.0)
        XCTAssertEqual([51], actualDeleteOne.1)

        let actualDeleteTwo = deleteFlagsWorksite.getFlagChanges(
            [
                testFlagSnapshot(3, -1, "newer"),
                testFlagSnapshot(4, -1, "pentag"),
            ],
            [],
            [:]
        )
        XCTAssertEqual([], actualDeleteTwo.0)
        XCTAssertEqual([51, 487], actualDeleteTwo.1)
    }

    func testComplexChanges() {
        let worksite = testNetworkWorksite(
            flags: [
                testNetworkFlag(42, "reasono"),
                testNetworkFlag(51, "newer"),
                testNetworkFlag(487, "pentag"),
                testNetworkFlag(521, "inasmu"),
            ]
        )
        let flagIdLookup: [Int64: Int64] = [
            23: 531,
            19: 25,
        ]
        let startFlags = [
            testFlagSnapshot(53, -1, "change-as-well"),
            testFlagSnapshot(63, -1, "skip-delete-not-in-existing"),
            testFlagSnapshot(73, -1, "reasono"),
            testFlagSnapshot(83, 645, "inasmu"),
        ]
        let changeFlags = [
            testFlagSnapshot(33, -1, "pentag"),
            testFlagSnapshot(23, -1, "skip-due-to-lookup"),
            testFlagSnapshot(43, -1, "add-flag"),
            testFlagSnapshot(53, -1, "change-as-well"),
        ]

        let actual = worksite.getFlagChanges(startFlags, changeFlags, flagIdLookup)
        XCTAssertEqual(
            [
                (Int64(43), testNetworkFlag(nil, "add-flag")),
                (Int64(53), testNetworkFlag(nil, "change-as-well")),
            ],
            actual.0
        )
        XCTAssertEqual([42, 521], actual.1)
    }
}

private func testFlagSnapshot(
    _ localId: Int64,
    _ id: Int64,
    _ reason: String,
    createdAt: Date = ChangeTestUtil.createdAtA,
    isHighPriority: Bool = false
) -> FlagSnapshot{
    FlagSnapshot(
        localId: localId,
        flag: FlagSnapshot.Flag(
            id: id,
            action: "",
            createdAt: createdAt,
            isHighPriority: isHighPriority,
            notes: "",
            reasonT: reason,
            reason: reason,
            requestedAction: "",
            involvesMyOrg: nil,
            haveContactedOtherOrg: nil,
            organizationIds: []
        )
    )
}

private func testNetworkFlag(
    _ id: Int64?,
    _ reason: String,
    createdAt: Date = ChangeTestUtil.createdAtA,
    isHighPriority: Bool = false,
    action: String? = nil,
    notes: String? = nil,
    requestedAction: String? = nil
) -> NetworkFlag{
    NetworkFlag(
        id: id,
        action: action,
        createdAt: createdAt,
        isHighPriority: isHighPriority,
        notes: notes,
        reasonT: reason,
        requestedAction: requestedAction,
        attr: nil
    )
}
