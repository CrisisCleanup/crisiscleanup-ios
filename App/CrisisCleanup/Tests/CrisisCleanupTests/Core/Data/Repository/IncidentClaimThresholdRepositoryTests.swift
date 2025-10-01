import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class IncidentClaimThresholdRepositoryTests: XCTestCase {
    private let claimThresholdDataSource = IncidentClaimThresholdDataSourceMock()
    private let accountInfoDataSource = AccountInfoDataSourceMock()
    private let workTypeAnalyzer = WorkTypeAnalyzerMock()
    private let appConfigRepository = AppConfigRepositoryMock()
    private let incidentSelector = IncidentSelectorMock()
    private let logger = AppLoggerMock()

    private var claimThresholdRepository: IncidentClaimThresholdRepository!

    override func setUp() async throws {
        let incident = EmptyIncident.copy {
            $0.id = 34
            $0.name = "test-incident"
        }
        incidentSelector.underlyingIncidentsData = IncidentsData(
            isLoading: false,
            selected: incident,
            incidents: [incident],
        )

        let accountData = emptyAccountData.copy {
            $0.id = 84
            $0.org = OrgData(id: 77, name: "org")
        }
        accountInfoDataSource.underlyingAccountData = accountData

        claimThresholdRepository = CrisisCleanupIncidentClaimThresholdRepository(
            claimThresholdDataSource: claimThresholdDataSource,
            accountInfoDataSource: accountInfoDataSource,
            workTypeAnalyzer: workTypeAnalyzer,
            appConfigRepository: appConfigRepository,
            incidentSelector: incidentSelector,
            logger: logger,
        )
    }

    private func makeClaimThreshold(
        _ claimCount: Int = 0,
        _ closeRatio: Float = 0.0,
        incidentId: Int64 = 34,
    ) -> IncidentClaimThreshold {
        IncidentClaimThreshold(
            incidentId: incidentId,
            claimedCount: claimCount,
            closedRatio: closeRatio,
        )
    }

    func testNonPositiveClaimCount() async throws {
        for i in -1...0 {
            let _ = await claimThresholdRepository.isWithinClaimCloseThreshold(1, i)
            XCTAssertEqual(0, claimThresholdDataSource.getIncidentClaimThresholdAccountIdIncidentIdCallsCount)
        }
    }

    func testSkipUnsynced() async throws {
        claimThresholdRepository.onWorksiteCreated(354)

        appConfigRepository.underlyingAppConfig = AppConfig(
            claimCountThreshold: 10,
            closedClaimRatioThreshold: 0.5,
        )

        let dbResults = [
            makeClaimThreshold(0, 0),
            makeClaimThreshold(10, 0.1),
            makeClaimThreshold(11, 0.1),
            makeClaimThreshold(9, 0.5),
            makeClaimThreshold(9, 0.5001),
            makeClaimThreshold(10, 0.5),
            makeClaimThreshold(11, 0.5001),
        ]
        let expectedUnder = [
            true,
            false,
            false,
            true,
            true,
            true,
            true,
        ]
        for i in expectedUnder.indices {
            claimThresholdDataSource.mockGetIncidentClaimThreshold(84, 34, mockReturn: dbResults[i])

            let expected = expectedUnder[i]
            let actual = await claimThresholdRepository.isWithinClaimCloseThreshold(354, 1)
            XCTAssertEqual(expected, actual)
        }
    }

    func testUnsyncedCounts() async throws {
        appConfigRepository.underlyingAppConfig = AppConfig(
            claimCountThreshold: 20,
            closedClaimRatioThreshold: 0.5,
        )
        claimThresholdDataSource.mockGetIncidentClaimThreshold(84, 34, mockReturn: makeClaimThreshold(10, 0.5))

        let analyzerResults = [
            ClaimCloseCounts(claimCount: 9, closeCount: 4),
            ClaimCloseCounts(claimCount: 10, closeCount: 4),
            ClaimCloseCounts(claimCount: 11, closeCount: 5),
            ClaimCloseCounts(claimCount: 9, closeCount: 5),
            ClaimCloseCounts(claimCount: 9, closeCount: 6),
            ClaimCloseCounts(claimCount: 10, closeCount: 5),
            ClaimCloseCounts(claimCount: 11, closeCount: 6),
        ]
        let expectedUnder = [
            true,
            false,
            false,
            true,
            true,
            true,
            true,
        ]

        for i in analyzerResults.indices {
            workTypeAnalyzer.mockCountUnsyncedClaimCloseWork(77, 34, [], mockReturn: analyzerResults[i])

            let expected = expectedUnder[i]
            let actual = await claimThresholdRepository.isWithinClaimCloseThreshold(354, 1)
            XCTAssertEqual(expected, actual)
        }
    }

    func testUnsyncedNegativeClaimCounts() async throws {
        appConfigRepository.underlyingAppConfig = AppConfig(
            claimCountThreshold: 20,
            closedClaimRatioThreshold: 0.5,
        )
        claimThresholdDataSource.mockGetIncidentClaimThreshold(84, 34, mockReturn: makeClaimThreshold(30, 0.3))

        let analyzerResults = [
            ClaimCloseCounts(claimCount: -9, closeCount: 1),
            ClaimCloseCounts(claimCount: -10, closeCount: 0),
            ClaimCloseCounts(claimCount: -10, closeCount: 1),
            ClaimCloseCounts(claimCount: -11, closeCount: 0),
        ]
        let expectedUnder = [
            false,
            false,
            true,
            true,
        ]

        for i in analyzerResults.indices {
            workTypeAnalyzer.mockCountUnsyncedClaimCloseWork(77, 34, [], mockReturn: analyzerResults[i])

            let expected = expectedUnder[i]
            let actual = await claimThresholdRepository.isWithinClaimCloseThreshold(354, 1)
            XCTAssertEqual(expected, actual)
        }
    }

    func testUnsyncedNegativeCloseCounts() async throws {
        appConfigRepository.underlyingAppConfig = AppConfig(
            claimCountThreshold: 20,
            closedClaimRatioThreshold: 0.5,
        )
        claimThresholdDataSource.mockGetIncidentClaimThreshold(84, 34, mockReturn: makeClaimThreshold(16, 0.75))

        let analyzerResults = [
            ClaimCloseCounts(claimCount: 4, closeCount: -2),
            ClaimCloseCounts(claimCount: 4, closeCount: -1),
            ClaimCloseCounts(claimCount: 4, closeCount: -2),
            ClaimCloseCounts(claimCount: 4, closeCount: -3),
        ]
        let expectedUnder = [
            true,
            true,
            true,
            false,
        ]

        for i in analyzerResults.indices {
            workTypeAnalyzer.mockCountUnsyncedClaimCloseWork(77, 34, [], mockReturn: analyzerResults[i])

            let expected = expectedUnder[i]
            let actual = await claimThresholdRepository.isWithinClaimCloseThreshold(354, 1)
            XCTAssertEqual(expected, actual)
        }
    }

    func testAnalyzerException() async throws {
        appConfigRepository.underlyingAppConfig = AppConfig(
            claimCountThreshold: 20,
            closedClaimRatioThreshold: 0.5,
        )
        claimThresholdDataSource.mockGetIncidentClaimThreshold(84, 34, mockReturn: makeClaimThreshold(19, 0.49999))

        workTypeAnalyzer.mockCountUnsyncedClaimCloseWork(
            77,
            34,
            [],
            errorMessage: "test-exception",
            mockReturn: ClaimCloseCounts(claimCount: 0, closeCount: 0),
        )

        let actual = await claimThresholdRepository.isWithinClaimCloseThreshold(354, 1)
        XCTAssertEqual(true, actual)

        let errorMessage = (logger.logErrorReceivedE as? GenericError)?.message
        XCTAssertEqual("test-exception", errorMessage)
    }
}

extension IncidentClaimThresholdDataSourceMock {
    func mockGetIncidentClaimThreshold(
        _ accountIdExpected: Int64,
        _ incidentIdExpected: Int64,
        mockReturn: IncidentClaimThreshold?,
    ) {
        getIncidentClaimThresholdAccountIdIncidentIdClosure = { (
            accountId: Int64,
            incidentId: Int64,
        ) in
            if accountId == accountIdExpected,
               incidentId == incidentIdExpected
            {
                return mockReturn
            }

            throw GenericError("Unxpected invocation of getIncidentClaimThreshold")
        }
    }
}

extension WorkTypeAnalyzerMock {
    func mockCountUnsyncedClaimCloseWork(
        _ orgIdExpected: Int64,
        _ incidentIdExpected: Int64,
        _ ignoreWorksiteIdsExpected: Set<Int64>,
        errorMessage: String = "",
        mockReturn: ClaimCloseCounts,
    ) {
        countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsClosure = { (
            orgId: Int64,
            incidentId: Int64,
            ignoreWorksiteIds: Set<Int64>,
        ) in
            if orgId == orgIdExpected,
               incidentId == incidentIdExpected,
               ignoreWorksiteIds == ignoreWorksiteIdsExpected
            {
                if errorMessage.isNotBlank {
                    throw GenericError(errorMessage)
                }
                return mockReturn
            }

            throw GenericError("Unxpected invocation of countUnsyncedClaimCloseWork")
        }
    }
}
