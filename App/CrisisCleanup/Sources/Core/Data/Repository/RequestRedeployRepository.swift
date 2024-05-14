public protocol RequestRedeployRepository {
    func getRequestedIncidents() async -> Set<Int64>
    func requestRedeploy(_ incidentId: Int64) async -> Bool
}

class CrisisCleanupRequestRedeployRepository: RequestRedeployRepository {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let writeApi: CrisisCleanupWriteApi
    private let logger: AppLogger

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        writeApi: CrisisCleanupWriteApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.accountDataRepository = accountDataRepository
        self.writeApi = writeApi
        logger = loggerFactory.getLogger("request-redeploy")
    }

    func getRequestedIncidents() async -> Set<Int64> {
        do {
            let ids = try await networkDataSource.getRequestRedeployIncidentIds()
            return ids
        } catch {
            logger.logError(error)
        }
        return Set()
    }

    func requestRedeploy(_ incidentId: Int64) async -> Bool {
        do {
            let organizationId = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst().org.id
            return try await writeApi.requestRedeploy(organizationId: organizationId, incidentId: incidentId)
        } catch {
            logger.logError(error)
        }
        return false
    }
}
