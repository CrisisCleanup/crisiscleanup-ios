import Foundation

public protocol IncidentClaimThresholdRepository {
    func saveIncidentClaimThresholds(
        _ accountId: Int64,
        _ incidentThresholds: [IncidentClaimThreshold],
    ) async

    func onWorksiteCreated(_ worksiteId: Int64)

    func isWithinClaimCloseThreshold(_ worksiteId: Int64, _ additionalClaimCount: Int) async -> Bool
}

class CrisisCleanupIncidentClaimThresholdRepository: IncidentClaimThresholdRepository {
    private let claimThresholdDataSource: IncidentClaimThresholdDataSource
    private let accountInfoDataSource: AccountInfoDataSource
    private let workTypeAnalyzer: WorkTypeAnalyzer
    private let appConfigRepository: AppConfigRepository
    private let incidentSelector: IncidentSelector
    private let logger: AppLogger

    private var worksitesCreated = Set<Int64>()

    init(
        claimThresholdDataSource: IncidentClaimThresholdDataSource,
        accountInfoDataSource: AccountInfoDataSource,
        workTypeAnalyzer: WorkTypeAnalyzer,
        appConfigRepository: AppConfigRepository,
        incidentSelector: IncidentSelector,
        logger: AppLogger,
    ) {
        self.claimThresholdDataSource = claimThresholdDataSource
        self.accountInfoDataSource = accountInfoDataSource
        self.workTypeAnalyzer = workTypeAnalyzer
        self.appConfigRepository = appConfigRepository
        self.incidentSelector = incidentSelector
        self.logger = logger
    }

    func onWorksiteCreated(_ worksiteId: Int64) {
        worksitesCreated.insert(worksiteId)
    }

    func saveIncidentClaimThresholds(
        _ accountId: Int64,
        _ incidentThresholds: [IncidentClaimThreshold],
    ) async {
        do {
            let records = incidentThresholds.map {
                IncidentClaimThresholdRecord(
                    userId: accountId,
                    incidentId: $0.incidentId,
                    userClaimCount: $0.claimedCount,
                    userCloseRatio: $0.closedRatio,
                )
            }
            try await claimThresholdDataSource.saveIncidentThresholds(accountId, records)
        } catch {
            logger.logError(error)
        }
    }

    func isWithinClaimCloseThreshold(
        _ worksiteId: Int64,
        _ additionalClaimCount: Int,
    ) async -> Bool {
        guard additionalClaimCount > 0 else {
            return true
        }

        do {
            let incidentId = try await incidentSelector.incidentId.eraseToAnyPublisher().asyncFirst()

            let accountData = try await accountInfoDataSource.accountData.eraseToAnyPublisher().asyncFirst()
            let accountId = accountData.id

            let thresholdConfig = try await appConfigRepository.appConfig.eraseToAnyPublisher().asyncFirst()
            let claimCountThreshold = thresholdConfig.claimCountThreshold
            let closeRatioThreshold = thresholdConfig.closedClaimRatioThreshold

            let currentIncidentThreshold = try claimThresholdDataSource.getIncidentClaimThreshold(
                accountId: accountId,
                incidentId: incidentId,
            )
            let userClaimCount = currentIncidentThreshold?.claimedCount ?? 0
            let userCloseRatio = currentIncidentThreshold?.closedRatio ?? 0

            var unsyncedCounts = ClaimCloseCounts(claimCount: 0, closeCount: 0)
            if !worksitesCreated.contains(worksiteId) {
                let orgId = accountData.org.id
                unsyncedCounts = try workTypeAnalyzer.countUnsyncedClaimCloseWork(
                    orgId: orgId,
                    incidentId: incidentId,
                    ignoreWorksiteIds: worksitesCreated,
                )
            }

            let unsyncedClaimCount = unsyncedCounts.claimCount

            let claimCount = userClaimCount + unsyncedClaimCount
            var closeRatio = userCloseRatio
            if claimCount > 0 {
                let userCloseCount = ceil(userCloseRatio * Float(userClaimCount))
                let closeCount = userCloseCount + Float(unsyncedCounts.closeCount)
                closeRatio = closeCount / Float(claimCount)
            }

            return claimCount < claimCountThreshold ||
            closeRatio >= closeRatioThreshold
        } catch {
            logger.logError(error)
        }

        return false
    }
}
