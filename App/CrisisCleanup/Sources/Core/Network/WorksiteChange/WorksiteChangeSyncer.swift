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
    private let jsonDecoder: JSONDecoder

    init() {
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

        print("Sync \(changes.count) worksite changes")

        // TODO: Do
        return WorksiteSyncResult(
            changeResults: [
                WorksiteSyncResult.ChangeResult(
                    id: 0,
                    isSuccessful: false,
                    isPartiallySuccessful: false,
                    isFail: true,
                    error: GenericError("Sync not yet implemented")
                )
            ],
            changeIds: WorksiteSyncResult.ChangeIds(
                networkWorksiteId: networkWorksiteId,
                flagIdMap: [:],
                noteIdMap: [:],
                workTypeIdMap: [:],
                workTypeKeyMap: [:],
                workTypeRequestIdMap: [:]
            )
        )
    }
}
