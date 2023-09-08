import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorkTypeChangeTests: XCTestCase {
    private let emptyChangesResult = (
        [String: WorkTypeChange](),
        [WorkTypeChange](),
        [Int64]()
    )

    private let now = dateNowRoundedSeconds

    func testWorkTypeChangeFrom_differentWorkType() {
        let workTypeA =
        WorkTypeSnapshot.WorkType(id: 1, status: "status", workType: "work-type-a")
        let workTypeB =
        WorkTypeSnapshot.WorkType(id: 1, status: "status", workType: "work-type-b")
        XCTAssertNil(workTypeA.changeFrom(workTypeB, 1, ChangeTestUtil.createdAtA))
    }

    func testWorkTypeChangeFrom_noChanges() {
        let workTypeA = WorkTypeSnapshot.WorkType(
            id: 1,
            status: "status",
            workType: "work-type",
            orgClaim: nil
        )
        let workTypeB = WorkTypeSnapshot.WorkType(
            id: 2,
            status: "status",
            workType: "work-type",
            orgClaim: nil
        )
        XCTAssertFalse(workTypeB.changeFrom(workTypeA, 2, ChangeTestUtil.createdAtA)!.hasChange)
    }

    func testWorkTypeChangeFrom_allChanges() {
        let workTypeA = WorkTypeSnapshot.WorkType(
            id: 1,
            status: "status",
            workType: "work-type",
            orgClaim: 45
        )
        let workTypeB = WorkTypeSnapshot.WorkType(
            id: 2,
            status: "status-change",
            workType: "work-type",
            orgClaim: nil
        )

        let expected = WorkTypeChange(
            localId: 2,
            networkId: -1,
            workType: workTypeB,
            changedAt: ChangeTestUtil.createdAtB,
            isClaimChange: true,
            isStatusChange: true
        )
        XCTAssertEqual(expected, workTypeB.changeFrom(workTypeA, 2, ChangeTestUtil.createdAtB))
    }

    func testWorkTypeChanges_noneEmpty() {
        let actual = testNetworkWorksite().getWorkTypeChanges([], [], ChangeTestUtil.updatedAtA)
        XCTAssertEqual(emptyChangesResult, actual)
    }

    func testWorkTypeChanges_noMatchingDelete() {
        let start = [testWorkTypeSnapshot("work-type", "status")]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 326,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-a"
                )
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, [], ChangeTestUtil.updatedAtA)
        XCTAssertEqual(emptyChangesResult, actual)
    }

    /**
     * No changes between snapshots that have been synced
     *   does not apply even when existing has the same work type with a different status.
     */
    func testWorkTypeChanges_noChanges() {
        let start = [testWorkTypeSnapshot("work-type-a", "status-b")]
        let change = [testWorkTypeSnapshot("work-type-a", "status-b")]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 326,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-a"
                )
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, change, ChangeTestUtil.updatedAtA)
        XCTAssertEqual(emptyChangesResult, actual)
    }

    /**
     * No changes between snapshots that are not synced
     *   is new when not in existing.
     */
    func testWorkTypeChanges_noChangesNotSyncedNotInExisting() {
        let start = [testWorkTypeSnapshot("work-type-a", "status-b", id: -1)]
        let change = [testWorkTypeSnapshot("work-type-a", "status-b", id: -1)]
        let worksite = testNetworkWorksite()
        let actual = worksite.getWorkTypeChanges(start, change, ChangeTestUtil.updatedAtA)
        XCTAssertEqual(
            (
                [
                    "work-type-a": WorkTypeChange(
                        localId: 59,
                        networkId: -1,
                        workType: WorkTypeSnapshot.WorkType(
                            id: -1,
                            status: "status-b",
                            workType: "work-type-a"
                        ),
                        changedAt: ChangeTestUtil.updatedAtA,
                        isClaimChange: true,
                        isStatusChange: true
                    )
                ],
                emptyChangesResult.1,
                emptyChangesResult.2
            ),
            actual
        )
    }

    /**
     * No changes between snapshots that are not synced
     *   is ignored when in existing and status is different.
     */
    func testWorkTypeChanges_noChangesNotSyncedInExisting() {
        let start = [testWorkTypeSnapshot("work-type-a", "status-b", id: -1)]
        let change = [testWorkTypeSnapshot("work-type-a", "status-b", id: -1)]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 326,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-a"
                )
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, change, ChangeTestUtil.updatedAtA)
        XCTAssertEqual(emptyChangesResult, actual)
    }

    func testWorkTypeChanges_notChangedFromExisting() {
        let start = [testWorkTypeSnapshot("work-type-a", "status-b")]
        let change = [testWorkTypeSnapshot("work-type-a", "status")]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 326,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-a"
                )
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, change, ChangeTestUtil.updatedAtA)
        XCTAssertEqual(emptyChangesResult, actual)
    }

    func testWorkTypeChanges_delete() {
        let start = [testWorkTypeSnapshot("work-type-a", "status-b")]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 326,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-a"
                ),
                NetworkWorkType(
                    id: 81,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    status: "status",
                    workType: "work-type-b"
                ),
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, [], ChangeTestUtil.updatedAtA)
        XCTAssertEqual(
            (
                emptyChangesResult.0,
                emptyChangesResult.1,
                [326]
            ),
            actual
        )
    }

    func testWorkTypeChanges_new() {
        let nextRecurAt = now.addingTimeInterval(10.days)
        let change = [testWorkTypeSnapshot("work-type-a", "status-b", id: -1)]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 81,
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: nil,
                    nextRecurAt: nextRecurAt,
                    phase: 2,
                    recur: "recur",
                    status: "status",
                    workType: "work-type-b"
                ),
            ]
        )

        let actual = worksite.getWorkTypeChanges([], change, ChangeTestUtil.updatedAtA)

        let expectedChanges = [
            "work-type-a": WorkTypeChange(
                localId: 59,
                networkId: -1,
                workType: WorkTypeSnapshot.WorkType(
                    id: -1,
                    status: "status-b",
                    workType: "work-type-a",
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: true,
                isStatusChange: true
            )
        ]
        XCTAssertEqual(
            (
                expectedChanges,
                emptyChangesResult.1,
                emptyChangesResult.2
            ),
            actual
        )
    }

    func testWorkTypeChanges_newInExisting() {
        let nextRecurAt = now.addingTimeInterval(10.days)
        let change = [testWorkTypeSnapshot("work-type-b", "status-b", id: -1)]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 81,
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: nil,
                    nextRecurAt: nextRecurAt,
                    phase: 2,
                    recur: "recur",
                    status: "status",
                    workType: "work-type-b"
                ),
            ]
        )

        let actual = worksite.getWorkTypeChanges([], change, ChangeTestUtil.updatedAtA)

        let expectedChanges = [
            WorkTypeChange(
                localId: 59,
                networkId: 81,
                workType: WorkTypeSnapshot.WorkType(
                    id: 81,
                    status: "status-b",
                    workType: "work-type-b",
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: nil,
                    nextRecurAt: nextRecurAt,
                    phase: 2,
                    recur: "recur"
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: false,
                isStatusChange: true
            )
        ]
        XCTAssertEqual(
            (
                emptyChangesResult.0,
                expectedChanges,
                emptyChangesResult.2
            ),
            actual
        )
    }

    func testWorkTypeChanges_changing() {
        let nextRecurAt = dateNowRoundedSeconds.addingTimeInterval(10.days)
        let start = [
            testWorkTypeSnapshot("work-type-a", "status-a"),
            testWorkTypeSnapshot("work-type-b", "status-b"),
            testWorkTypeSnapshot("work-type-c", "status-c", orgClaim: 48),
            testWorkTypeSnapshot("work-type-d", "status-d"),
        ]
        let change = [
            testWorkTypeSnapshot("work-type-a", "status-a-change", localId: 61),
            testWorkTypeSnapshot("work-type-b", "status-b", orgClaim: 456, localId: 62),
            testWorkTypeSnapshot("work-type-c", "status-c", localId: 63),
            testWorkTypeSnapshot("work-type-d", "status-d", orgClaim: 89, localId: 64),
        ]
        let worksite = testNetworkWorksite(
            workTypes: [
                NetworkWorkType(
                    id: 81,
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: nil,
                    nextRecurAt: nextRecurAt,
                    phase: 2,
                    recur: "recur",
                    status: "status",
                    workType: "work-type-b"
                ),
                NetworkWorkType(
                    id: 82,
                    createdAt: ChangeTestUtil.createdAtB,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: 3,
                    recur: nil,
                    status: "status",
                    workType: "work-type-c"
                ),
                NetworkWorkType(
                    id: 91,
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: 54,
                    nextRecurAt: nextRecurAt,
                    phase: 1,
                    recur: "recur",
                    status: "status-d",
                    workType: "work-type-d"
                ),
                NetworkWorkType(
                    id: 99,
                    createdAt: ChangeTestUtil.createdAtB,
                    orgClaim: 471,
                    nextRecurAt: nil,
                    phase: 4,
                    recur: nil,
                    status: "status-a-change",
                    workType: "work-type-a"
                ),
            ]
        )
        let actual = worksite.getWorkTypeChanges(start, change, ChangeTestUtil.updatedAtA)
        let expectedChanges = [
            WorkTypeChange(
                localId: 61,
                networkId: 99,
                workType: WorkTypeSnapshot.WorkType(
                    id: 99,
                    status: "status-a-change",
                    workType: "work-type-a",
                    createdAt: ChangeTestUtil.createdAtB,
                    orgClaim: nil,
                    phase: 4
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: true,
                isStatusChange: false
            ),
            WorkTypeChange(
                localId: 62,
                networkId: 81,
                workType: WorkTypeSnapshot.WorkType(
                    id: 81,
                    status: "status-b",
                    workType: "work-type-b",
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: 456,
                    nextRecurAt: nextRecurAt,
                    phase: 2,
                    recur: "recur"
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: true,
                isStatusChange: true
            ),
            WorkTypeChange(
                localId: 63,
                networkId: 82,
                workType: WorkTypeSnapshot.WorkType(
                    id: 82,
                    status: "status-c",
                    workType: "work-type-c",
                    createdAt: ChangeTestUtil.createdAtB,
                    orgClaim: nil,
                    phase: 3
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: false,
                isStatusChange: true
            ),
            WorkTypeChange(
                localId: 64,
                networkId: 91,
                workType: WorkTypeSnapshot.WorkType(
                    id: 91,
                    status: "status-d",
                    workType: "work-type-d",
                    createdAt: ChangeTestUtil.createdAtA,
                    orgClaim: 89,
                    nextRecurAt: nextRecurAt,
                    phase: 1,
                    recur: "recur"
                ),
                changedAt: ChangeTestUtil.updatedAtA,
                isClaimChange: true,
                isStatusChange: false
            ),
        ]
        XCTAssertEqual(emptyChangesResult.0, actual.0)
        XCTAssertEqual(
            expectedChanges.sorted(by: { a, b in a.localId < b.localId }),
            actual.1.sorted(by: { a, b in a.localId < b.localId })
        )
        XCTAssertEqual(emptyChangesResult.2, actual.2)
    }

    func testWorkTypeChanges_complex() {
        // TODO Cover all cases especially any not covered above
    }
}

private func testWorkTypeSnapshot(
    _ workType: String = "work-type",
    _ status: String = "status",
    orgClaim: Int64? = nil,
    createdAt: Date? = nil,
    id: Int64 = 53,
    localId: Int64 = 59
) -> WorkTypeSnapshot {
    WorkTypeSnapshot(
        localId: localId,
        workType: WorkTypeSnapshot.WorkType(
            id: id,
            status: status,
            workType: workType,
            createdAt: createdAt,
            orgClaim: orgClaim
        )
    )
}
