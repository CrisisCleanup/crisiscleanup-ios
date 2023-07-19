import Foundation

public protocol WorksiteChangeSyncer {
    func sync(
        _ accountData: AccountData,
        _ startingReferenceChange: SavedWorksiteChange,
        _ sortedChanges: [SavedWorksiteChange],
        _ hasPriorUnsyncedChanges: Bool,
        _ networkWorksiteId: Int64,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64],
        affiliateOrganizations: Set<Int64>,
        syncLogger: SyncLogger
    ) async throws -> WorksiteSyncResult
}

class NetworkWorksiteChangeSyncer: WorksiteChangeSyncer {
    private let changeSetOperator: WorksiteChangeSetOperator
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let writeApiClient: CrisisCleanupWriteApi
    private let networkMonitor: NetworkMonitor
    private let appEnv: AppEnv

    private let jsonDecoder: JSONDecoder

    init(
        changeSetOperator: WorksiteChangeSetOperator,
        networkDataSource: CrisisCleanupNetworkDataSource,
        writeApiClient: CrisisCleanupWriteApi,
        networkMonitor: NetworkMonitor,
        appEnv: AppEnv
    ) {
        self.changeSetOperator = changeSetOperator
        self.networkDataSource = networkDataSource
        self.writeApiClient = writeApiClient
        self.networkMonitor = networkMonitor
        self.appEnv = appEnv

        jsonDecoder = JsonDecoderFactory().decoder()
    }

    private func deserializeChanges(_ savedChange: SavedWorksiteChange) throws -> SyncWorksiteChange {
        let worksiteChange: WorksiteChange
        let version = savedChange.dataVersion
        switch version {
        case 1, 2, 3, 4:
            let encodedData = savedChange.serializedData.data(using: .utf8)!
            worksiteChange = try jsonDecoder.decode(WorksiteChange.self, from: encodedData)
        default: fatalError("Worksite change version \(version) not implemented")
        }

        return SyncWorksiteChange(
            id: savedChange.id,
            createdAt: savedChange.createdAt,
            syncUuid: savedChange.syncUuid,
            isPartiallySynced: savedChange.isPartiallySynced,
            worksiteChange: worksiteChange
        )
    }

    func sync(
        _ accountData: AccountData,
        _ startingReferenceChange: SavedWorksiteChange,
        _ sortedChanges: [SavedWorksiteChange],
        _ hasPriorUnsyncedChanges: Bool,
        _ networkWorksiteId: Int64,
        flagIdLookup: [Int64 : Int64],
        noteIdLookup: [Int64 : Int64],
        workTypeIdLookup: [Int64 : Int64],
        affiliateOrganizations: Set<Int64>,
        syncLogger: SyncLogger
    ) async throws -> WorksiteSyncResult {
        let changes = try sortedChanges.map { try deserializeChanges($0) }

        let syncManager = WorksiteChangeProcessor(
            changeSetOperator: changeSetOperator,
            networkDataSource: networkDataSource,
            writeApiClient: writeApiClient,
            accountData: accountData,
            networkMonitor: networkMonitor,
            appEnv: appEnv,
            syncLogger: syncLogger,
            hasPriorUnsyncedChanges: hasPriorUnsyncedChanges,
            networkWorksiteId: networkWorksiteId,
            affiliateOrganizations: affiliateOrganizations,
            flagIdLookup: flagIdLookup,
            noteIdLookup: noteIdLookup,
            workTypeIdLookup: workTypeIdLookup
        )
        try await syncManager.process(
            startingReferenceChange: deserializeChanges(startingReferenceChange),
            sortedChanges: changes
        )
        return syncManager.syncResult
    }
}
