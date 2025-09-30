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

    private var incidentClaimThresholdRepository: IncidentClaimThresholdRepository!

    override func setUp() async throws {
        incidentClaimThresholdRepository = CrisisCleanupIncidentClaimThresholdRepository(
            claimThresholdDataSource: claimThresholdDataSource,
            accountInfoDataSource: accountInfoDataSource,
            workTypeAnalyzer: workTypeAnalyzer,
            appConfigRepository: appConfigRepository,
            incidentSelector: incidentSelector,
            logger: logger,
        )
    }

}
