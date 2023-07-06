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
        // TODO: Do
        WorksiteSyncResult(
            changeResults: [],
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
