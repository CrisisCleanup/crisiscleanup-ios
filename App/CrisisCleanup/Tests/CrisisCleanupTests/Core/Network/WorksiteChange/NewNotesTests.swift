import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class NewNoteTests: XCTestCase {
    func testNoNewNotes() {
        let snapshot = testWorksiteSnapshot(
            notes: [
                testNoteSnapshot("", -1, -1),
                testNoteSnapshot("not-bank", 53, -1),
                testNoteSnapshot("not-bank", -1, 46),
            ]
        )
        let actual = snapshot.getNewNetworkNotes([53: 35])
        XCTAssertTrue(actual.isEmpty)
    }

    func testNewNotes() {
        let snapshot = testWorksiteSnapshot(
            notes: [
                testNoteSnapshot("not-bank-a", 44, -1, createdAt: ChangeTestUtil.createdAtA),
                testNoteSnapshot("not-bank-b", 53, -1),
            ]
        )
        let actual = snapshot.getNewNetworkNotes([53: 35])
        let expected = [
            (Int64(44), NetworkNote(nil, ChangeTestUtil.createdAtA, false, "not-bank-a"))
        ]
        XCTAssertEqual(expected, actual)
    }

    func testFilterDupicateNotes() {
        let now = dateNowRoundedSeconds
        let nineDaysAgo = now.addingTimeInterval(-9.days)
        let eightDaysAgo = now.addingTimeInterval(-8.days)
        let sevenDaysAgo = now.addingTimeInterval(-7.days)
        let twoDaysAgo = now.addingTimeInterval(-2.days)
        let oneDayAgo = now.addingTimeInterval(-1.days)
        let worksite = testNetworkWorksite(
            notes: [
                NetworkNote(11, nineDaysAgo, false, "note-a"),
                NetworkNote(12, eightDaysAgo, true, "note-b"),
                NetworkNote(13, sevenDaysAgo, false, "note-c"),
                NetworkNote(14, twoDaysAgo, true, "note-d"),
                NetworkNote(15, oneDayAgo, false, "note-e"),
            ]
        )

        let actual = worksite.filterDuplicateNotes(
            [
                (1, NetworkNote(11, now, false, "note-a")),
                (2, NetworkNote(-1, eightDaysAgo.addingTimeInterval(1.minutes), false, "note-b")),
                (3, NetworkNote(-1, sevenDaysAgo.addingTimeInterval(11.hours), false, " note-c")),
                (4, NetworkNote(-1, sevenDaysAgo, true, "new-note-a")),
                (5, NetworkNote(-1, now, false, "note-d")),
                (6, NetworkNote(-1, oneDayAgo.addingTimeInterval(-11.hours), true, "note-e")),
            ]
        )

        let expected = [
            (Int64(1), NetworkNote(11, now, false, "note-a")),
            (Int64(4), NetworkNote(-1, sevenDaysAgo, true, "new-note-a")),
            (Int64(5), NetworkNote(-1, now, false, "note-d")),
        ]
        XCTAssertEqual(actual, expected)
    }
}

internal let emptyCoreSnapshot = CoreSnapshot(
    id: 1,
    address: "",
    autoContactFrequencyT: "",
    caseNumber: "",
    city: "",
    county: "",
    createdAt: dateNowRoundedSeconds,
    email: "",
    favoriteId: 0,
    formData: [:],
    incidentId: 1,
    keyWorkTypeId: 1,
    latitude: 0.0,
    longitude: 0.0,
    name: "",
    networkId: 1,
    phone1: "",
    phone2: "",
    plusCode: "",
    postalCode: "",
    reportedBy: 1,
    state: "",
    svi: 0,
    updatedAt: nil,
    what3Words: "",
    isAssignedToOrgMember: false
)

internal func testWorksiteSnapshot(
    core: CoreSnapshot = emptyCoreSnapshot,
    flags: [FlagSnapshot] = [],
    notes: [NoteSnapshot] = [],
    workTypes: [WorkTypeSnapshot] = []
) -> WorksiteSnapshot {
    WorksiteSnapshot(
        core: core,
        flags: flags,
        notes: notes,
        workTypes: workTypes
    )
}

private func testNoteSnapshot(
    _ note: String,
    _ localId: Int64 = -1,
    _ networkId: Int64 = -1,
    createdAt: Date = dateNowRoundedSeconds
) -> NoteSnapshot {
    NoteSnapshot(
        localId: localId,
        note: NoteSnapshot.Note(
            id: networkId,
            createdAt: createdAt,
            isSurvivor: false,
            note: note
        )
    )
}
