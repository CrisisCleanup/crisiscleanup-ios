public protocol RequestRedeployRepository {
    func getRequestedIncidents() async -> Set<Int64>
    func requestRedeploy(incidentId: Int64) async -> Bool
}

class CrisisCleanupRequestRedeployRepository: RequestRedeployRepository {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let accountApi: CrisisCleanupAccountApi
    private let logger: AppLogger

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        accountApi: CrisisCleanupAccountApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.accountDataRepository = accountDataRepository
        self.accountApi = accountApi
        logger = loggerFactory.getLogger("request-redeploy")
    }

    func getRequestedIncidents() async -> Set<Int64> {
        await networkDataSource.getRequestRedeployIncidentIds()
    }

    func requestRedeploy(incidentId: Int64) async -> Bool {
        do {
            let organizationId = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst().org.id
            return try await accountApi.requestRedeploy(organizationId: organizationId, incidentId: incidentId)
        } catch {
            logger.logError(error)
        }
        return false
    }
}
