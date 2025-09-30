import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class WorkTypeAnalyzerTests: XCTestCase {
    private var worksiteChangeDao: WorksiteChangeDataProviderMock!

    private var workTypeAnalyzer: WorkTypeAnalyzer!

    private let jsonEncoder = JsonEncoderFactory().encoder()
    private let jsonDecoder = JsonDecoderFactory().decoder()

    override func setUp() async throws {
        worksiteChangeDao = .init()
        workTypeAnalyzer = WorksiteChangeWorkTypeAnalyzer(worksiteChangeDao: worksiteChangeDao)
    }

    private func makeWorksiteChange(
        _ snapshotStart: WorksiteSnapshot?,
        _ snapshotChange: WorksiteSnapshot,
        _ worksiteId: Int64,
    ) throws -> WorksiteSerializedChange {
        WorksiteSerializedChange(
            worksiteId: worksiteId,
            changeData: try jsonEncoder.encodeToString(
                WorksiteChange(
                    isWorksiteDataChange: false,
                    start: snapshotStart,
                    change: snapshotChange,
                    requestWorkTypes: nil,
                    releaseWorkTypes: nil,
                ),
            ),
        )
    }

    private func worksiteChange10(
        incidentId: Int64 = 152,
        worksiteId: Int64 = 342,
        orgId: Int64 = 52,
        networkWorksiteId: Int64 = 40,
    ) throws -> WorksiteSerializedChange {
        try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                networkWorksiteId: networkWorksiteId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1),
                ],
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1, status: .closedOutOfScope, orgId: orgId),
                ],
            ),
            worksiteId,
        )
    }

    private func worksiteChangeN10(
        incidentId: Int64 = 152,
        worksiteId: Int64 = 343,
        orgId: Int64 = 52,
        networkWorksiteId: Int64 = 41,
    ) throws -> WorksiteSerializedChange {
        try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                networkWorksiteId: networkWorksiteId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1, orgId: orgId),
                ],
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1),
                ],
            ),
            worksiteId,
        )
    }

    private func worksiteChange21(
        incidentId: Int64 = 152,
        worksiteId: Int64 = 344,
        orgId: Int64 = 52,
        networkWorksiteId: Int64 = 42,
    ) throws -> WorksiteSerializedChange {
        try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                networkWorksiteId: networkWorksiteId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .closedOutOfScope),
                    makeWorkTypeSnapshot(localId: 3),
                    makeWorkTypeSnapshot(localId: 4),
                ],
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .closedRejected),
                    makeWorkTypeSnapshot(localId: 3, status: .closedDuplicate, orgId: orgId),
                    makeWorkTypeSnapshot(localId: 4, orgId: orgId),
                ],
            ),
            worksiteId,
        )
    }

    private func worksiteChangeN01(
        incidentId: Int64 = 152,
        worksiteId: Int64 = 345,
        orgId: Int64 = 52,
        networkWorksiteId: Int64 = 43,
    ) throws -> WorksiteSerializedChange {
        try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                networkWorksiteId: networkWorksiteId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1, status: .closedCompleted, orgId: orgId),
                ],
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 1, orgId: orgId),
                ],
            ),
            worksiteId,
        )
    }

    func testSeparateChanges() async throws {
        let dbChanges = [
            try worksiteChange10(),
            try worksiteChangeN10(),
            try worksiteChange21(),
            try worksiteChangeN01(),
        ]
        let expectedCounts = [
            ClaimCloseCounts(claimCount: 1, closeCount: 1),
            ClaimCloseCounts(claimCount: -1, closeCount: 0),
            ClaimCloseCounts(claimCount: 2, closeCount: 1),
            ClaimCloseCounts(claimCount: 0, closeCount: -1),
        ]
        for i in dbChanges.indices {
            worksiteChangeDao.mockClosure(52, mockReturn: [dbChanges[i]])

            let expected = expectedCounts[i]
            let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
                orgId: 52,
                incidentId: 152,
                ignoreWorksiteIds: [],
            )
            XCTAssertEqual(expected, actual)
        }
    }

    func testCombinedChanges() async throws {
        worksiteChangeDao.mockClosure(52, mockReturn: [
            try worksiteChange10(),
            try worksiteChangeN10(),
            try worksiteChange21(),
        ])

        let expected = ClaimCloseCounts(claimCount: 2, closeCount: 2)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: 52,
            incidentId: 152,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }

    func testLocalWorksiteChanges() async throws {
        worksiteChangeDao.mockClosure(52, mockReturn: [
            try worksiteChange10(worksiteId: 11),
            try worksiteChangeN10(worksiteId: 110),
            try worksiteChange21(worksiteId: 21),
        ])

        let expected = ClaimCloseCounts(claimCount: 0, closeCount: 0)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: 52,
            incidentId: 152,
            ignoreWorksiteIds: [11, 21, 110],
        )
        XCTAssertEqual(expected, actual)
    }

    func testNoNetworkWorksiteId() async throws {
        worksiteChangeDao.mockClosure(52, mockReturn: [
            try worksiteChange10(networkWorksiteId: 0),
            try worksiteChangeN10(networkWorksiteId: 0),
            try worksiteChange21(networkWorksiteId: 0),
        ])

        let expected = ClaimCloseCounts(claimCount: 0, closeCount: 0)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: 52,
            incidentId: 152,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }

    func testDifferentIncident() async throws {
        worksiteChangeDao.mockClosure(52, mockReturn: [
            try worksiteChange10(incidentId: 52),
            try worksiteChangeN10(),
            try worksiteChange21(),
        ])

        let expected = ClaimCloseCounts(claimCount: 1, closeCount: 1)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: 52,
            incidentId: 152,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }

    func testNoDistinguisingClaimChanges() async throws {
        let orgId: Int64 = 42
        let incidentId: Int64 = 152
        let worksiteChange = try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .openUnresponsive),
                    makeWorkTypeSnapshot(localId: 3, status: .closedIncomplete, orgId: orgId),
                ]
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .needUnfilled),
                    makeWorkTypeSnapshot(localId: 3, status: .closedDoneByOthers, orgId: orgId),
                ]
            ),
            152,
        )

        worksiteChangeDao.mockClosure(orgId, mockReturn: [worksiteChange])

        let expected = ClaimCloseCounts(claimCount: 0, closeCount: 0)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: orgId,
            incidentId: incidentId,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }

    func testNoDistinguisingCloseChange() async throws {
        let orgId: Int64 = 42
        let incidentId: Int64 = 152
        let worksiteChange = try makeWorksiteChange(
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .closedOutOfScope),
                    makeWorkTypeSnapshot(localId: 3, status: .closedIncomplete),
                    makeWorkTypeSnapshot(localId: 4, orgId: orgId),
                ]
            ),
            makeWorksiteSnapshot(
                incidentId: incidentId,
                workTypes: [
                    makeWorkTypeSnapshot(localId: 2, status: .openUnresponsive),
                    makeWorkTypeSnapshot(localId: 3, status: .openAssigned, orgId: orgId),
                    makeWorkTypeSnapshot(localId: 4, status: .closedDoneByOthers),
                ]
            ),
            152,
        )

        worksiteChangeDao.mockClosure(orgId, mockReturn: [worksiteChange])

        let expected = ClaimCloseCounts(claimCount: 0, closeCount: 0)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: orgId,
            incidentId: incidentId,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }

    func testMultipleCommits() async throws {
        let orgId: Int64 = 42
        let worksiteId: Int64 = 88
        let incidentId: Int64 = 152

        worksiteChangeDao.mockClosure(
            orgId,
            mockReturn: [
                try worksiteChangeN10(worksiteId: worksiteId),
                try worksiteChange10(worksiteId: worksiteId),
                try worksiteChange21(worksiteId: worksiteId),
                try worksiteChangeN01(worksiteId: worksiteId),
            ]
        )

        let expected = ClaimCloseCounts(claimCount: 0, closeCount: 0)
        let actual = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
            orgId: orgId,
            incidentId: incidentId,
            ignoreWorksiteIds: [],
        )
        XCTAssertEqual(expected, actual)
    }
}

private func makeWorksiteSnapshot(
    incidentId: Int64 = 152,
    networkWorksiteId: Int64 = 6252,
    workTypes: [WorkTypeSnapshot] = [],
) -> WorksiteSnapshot {
    WorksiteSnapshot(
        core: makeCoreSnapshot(
            incidentId: incidentId,
            networkId: networkWorksiteId,
        ),
        flags: [],
        notes: [],
        workTypes: workTypes,
    )
}

private func makeCoreSnapshot(
    incidentId: Int64 = 152,
    networkId: Int64 = 6252,
) -> CoreSnapshot {
    emptyCoreSnapshot.copy {
        $0.incidentId = incidentId
        $0.networkId = networkId
    }
}

private func makeWorkTypeSnapshot(
    localId: Int64,
    status: WorkTypeStatus = .openUnassigned,
    orgId: Int64? = nil,
) -> WorkTypeSnapshot {
    emptyWorkTypeSnapshot.copy { a in
        a.localId = localId
        a.workType = emptyWorkTypeSnapshot.workType.copy { b in
            b.orgClaim = orgId
            b.status = status.literal
        }
    }
}

private let emptyWorkTypeSnapshot = WorkTypeSnapshot(
    localId: 0,
    workType: WorkTypeSnapshot.WorkType(
        id: 0,
        status: "",
        workType: "",
    ),
)

extension WorksiteChangeDataProviderMock {
    func mockClosure(
        _ orgIdExpected: Int64,
        mockReturn: [WorksiteSerializedChange],
    ) {
        getOrgChangesClosure = { (
            orgId: Int64
        ) in
            if orgId == orgIdExpected
            {
                return mockReturn
            }

            throw GenericError("Unxpected invocation of getOrgChanges")
        }
    }
}
