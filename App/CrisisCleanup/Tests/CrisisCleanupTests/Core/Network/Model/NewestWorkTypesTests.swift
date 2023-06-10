import XCTest
@testable import CrisisCleanup

final class NewestWorkTypeTests: XCTestCase {
    private let createdAtA = Date.now.addingTimeInterval(16.hours)

    func testNoWorkTypes() {
        let newestWorkTypes = NetworkWorksiteFull.getNewestWorkTypes([], [:])
        let newestKeyWorkType = NetworkWorksiteFull.getKeyWorkType(nil, [], [:])
        XCTAssertEqual([], newestWorkTypes)
        XCTAssertNil(newestKeyWorkType)

        let workTypesShort = NetworkWorksiteShort.getNewestWorkTypes([], [:])
        let keyWorkTypeShort = NetworkWorksiteShort.getKeyWorkType(nil, [], [:])
        XCTAssertEqual([], workTypesShort)
        XCTAssertNil(keyWorkTypeShort)
    }

    func testNoDuplicateWorkTypes() {
        let keyWorkType = testWorkType(2)
        let workTypes = [
            testWorkType(75),
            testWorkType(1),
            testWorkType(2),
        ]

        let workTypeMap = NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
        let newestWorkTypes = NetworkWorksiteFull.getNewestWorkTypes(workTypes, workTypeMap)
        let newestKeyWorkType = NetworkWorksiteFull.getKeyWorkType(keyWorkType, workTypes, workTypeMap)

        XCTAssertEqual(
            [
                testWorkType(75),
                testWorkType(1),
                testWorkType(2),
            ],
            newestWorkTypes
        )
        XCTAssertEqual(testWorkType(2), newestKeyWorkType)
    }

    func testNoDuplicateWorkTypes_short() {
        let workTypes = [
            testWorkTypeShort(75),
            testWorkTypeShort(1),
            testWorkTypeShort(2),
        ]
        let keyWorkType = NetworkWorksiteFull.KeyWorkTypeShort(
            workType: "work-type-2",
            orgClaim: nil,
            status: "status"
        )

        let workTypeMap = NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
        let newestWorkTypes = NetworkWorksiteShort.getNewestWorkTypes(workTypes, workTypeMap)
        let newestKeyWorkType = NetworkWorksiteShort.getKeyWorkType(keyWorkType, workTypes, workTypeMap)

        XCTAssertEqual(workTypes, newestWorkTypes)
        XCTAssertEqual(keyWorkType, newestKeyWorkType)
    }

    func testDuplicateWorkTypes() {
        let keyWorkType = testWorkType(2, workType: "work-type-m")
        let workTypes = [
            testWorkType(81, workType: "work-type-b"),
            testWorkType(2, workType: "work-type-m"),
            testWorkType(155, workType: "work-type-a"),
            testWorkType(1, workType: "work-type-b"),
            testWorkType(75, workType: "work-type-a"),
            testWorkType(
                52,
                createdAt: createdAtA,
                orgClaim: 152,
                status: "status-high",
                workType: "work-type-m"
            ),
            testWorkType(21, workType: "work-type-b"),
        ]

        let workTypeMap = NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
        let newestWorkTypes = NetworkWorksiteFull.getNewestWorkTypes(workTypes, workTypeMap)
        let newestKeyWorkType = NetworkWorksiteFull.getKeyWorkType(keyWorkType, workTypes, workTypeMap)

        XCTAssertEqual(
            [
                testWorkType(81, workType: "work-type-b"),
                testWorkType(155, workType: "work-type-a"),
                testWorkType(
                    52,
                    createdAt: createdAtA,
                    orgClaim: 152,
                    status: "status-high",
                    workType: "work-type-m"
                ),
            ],
            newestWorkTypes
        )
        XCTAssertEqual(
            testWorkType(
                52,
                createdAt: createdAtA,
                orgClaim: 152,
                status: "status-high",
                workType: "work-type-m"
            ),
            newestKeyWorkType
        )
    }

    func testDuplicateWorkTypes_short() {
        let keyWorkType = NetworkWorksiteFull.KeyWorkTypeShort(
            workType: "work-type-m",
            orgClaim: nil,
            status: "status"
        )
        let workTypes = [
            testWorkTypeShort(81, workType: "work-type-b"),
            testWorkTypeShort(2, workType: "work-type-m"),
            testWorkTypeShort(155, workType: "work-type-a"),
            testWorkTypeShort(1, workType: "work-type-b"),
            testWorkTypeShort(75, workType: "work-type-a"),
            testWorkTypeShort(
                52,
                orgClaim: 158,
                status: "status-high",
                workType: "work-type-m"
            ),
            testWorkTypeShort(21, workType: "work-type-b"),
        ]

        let workTypeMap = NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
        let newestWorkTypes = NetworkWorksiteShort.getNewestWorkTypes(workTypes, workTypeMap)
        let newestKeyWorkType = NetworkWorksiteShort.getKeyWorkType(keyWorkType, workTypes, workTypeMap)

        XCTAssertEqual(
            [
                testWorkTypeShort(81, workType: "work-type-b"),
                testWorkTypeShort(155, workType: "work-type-a"),
                testWorkTypeShort(
                    52,
                    orgClaim: 158,
                    status: "status-high",
                    workType: "work-type-m"
                ),
            ],
            newestWorkTypes
        )
        XCTAssertEqual(
            NetworkWorksiteFull.KeyWorkTypeShort(
                workType: "work-type-m",
                orgClaim: 158,
                status: "status-high"
            ),
            newestKeyWorkType
        )
    }

    func testDuplicateWorkTypes_differentKeyWorkType() {
        let keyWorkType = testWorkType(2, workType: "work-type-m")
        let workTypes = [
            testWorkType(81, workType: "work-type-b"),
            testWorkType(2, workType: "work-type-m"),
            testWorkType(155, workType: "work-type-a"),
            testWorkType(1, workType: "work-type-b"),
            testWorkType(75, workType: "work-type-a"),
            testWorkType(
                52,
                createdAt: createdAtA,
                orgClaim: 152,
                status: "status-high",
                workType: "work-type-m"
            ),
            testWorkType(21, workType: "work-type-b")
        ]

        let workTypeMap = NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
        let newestWorkTypes = NetworkWorksiteFull.getNewestWorkTypes(workTypes, workTypeMap)
        let newestKeyWorkType = NetworkWorksiteFull.getKeyWorkType(keyWorkType, workTypes, workTypeMap)

        XCTAssertEqual(
            [
                testWorkType(81, workType: "work-type-b"),
                testWorkType(155, workType: "work-type-a"),
                testWorkType(
                    52,
                    createdAt: createdAtA,
                    orgClaim: 152,
                    status: "status-high",
                    workType: "work-type-m"
                )
            ],
            newestWorkTypes
        )
        XCTAssertEqual(
            testWorkType(
                52,
                createdAt: createdAtA,
                orgClaim: 152,
                status: "status-high",
                workType: "work-type-m"
            ),
            newestKeyWorkType
        )
    }
}

private let now = Date.now

internal func testWorkType(
    _ id: Int64,
    createdAt: Date = now,
    orgClaim: Int64? = nil,
    nextRecurAt: Date? = nil,
    phase: Int = 0,
    recur: String = "recur",
    status: String = "status",
    workType: String? = nil
) -> NetworkWorkType {
    return NetworkWorkType(
        id: id,
        createdAt: createdAt,
        orgClaim: orgClaim,
        nextRecurAt: nextRecurAt,
        phase: phase,
        recur: recur,
        status: status,
        workType: workType ?? "work-type-\(id)"
    )
}

internal func testWorkTypeShort(
    _ id: Int64,
    orgClaim: Int64? = nil,
    status: String = "status",
    workType: String? = nil
) -> NetworkWorksiteFull.WorkTypeShort {
    return NetworkWorksiteFull.WorkTypeShort(
        id: id,
        workType: workType ?? "work-type-\(id)",
        orgClaim: orgClaim,
        status: status
    )
}
