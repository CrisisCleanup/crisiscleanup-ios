public protocol IncidentClaimThresholdRepository {
    func saveIncidentClaimThresholds(
        _ accountId: Int64,
        _ incidentThresholds: [IncidentClaimThreshold],
    ) async

    func onWorksiteCreated(_ worksiteId: Int64)

    func isWithinClaimCloseThreshold(_ worksiteId: Int64, _ additionalClaimCount: Int) async -> Bool
}

class CrisisCleanupIncidentClaimThresholdRepository: IncidentClaimThresholdRepository {
    private let incidentDao: IncidentDao
    private let accountInfoDataSource: AccountInfoDataSource
    // private let workTypeAnalyzer: WorkTypeAnalyzer
    private let appConfigRepository: AppConfigRepository
    private let incidentSelector: IncidentSelector
    private let logger: AppLogger

    private var worksitesCreated = Set<Int64>()

    init(
        incidentDao: IncidentDao,
        accountInfoDataSource: AccountInfoDataSource,
        appConfigRepository: AppConfigRepository,
        incidentSelector: IncidentSelector,
        loggerFactory: AppLoggerFactory,
    ) {
        self.incidentDao = incidentDao
        self.accountInfoDataSource = accountInfoDataSource
        self.appConfigRepository = appConfigRepository
        self.incidentSelector = incidentSelector
        logger = loggerFactory.getLogger("incident-claim-threshold")
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
            try await incidentDao.saveIncidentThresholds(accountId, records)
        } catch {
            logger.logError(error)
        }
    }

    func isWithinClaimCloseThreshold(
        _ worksiteId: Int64,
        _ additionalClaimCount: Int,
    ) async -> Bool {
        // TODO: Query and compare
        false
    }
}
