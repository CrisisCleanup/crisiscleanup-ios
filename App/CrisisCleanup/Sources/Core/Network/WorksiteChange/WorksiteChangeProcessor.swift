import Atomics
import Foundation

class WorksiteChangeProcessor {
    private let changeSetOperator: WorksiteChangeSetOperator
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let writeApiClient: CrisisCleanupWriteApi
    private let accountData: AccountData
    private let networkMonitor: NetworkMonitor
    private let appEnv: AppEnv
    private let syncLogger: SyncLogger
    private var hasPriorUnsyncedChanges: Bool
    private var networkWorksiteId: Int64
    private let affiliateOrganizations: Set<Int64>

    private var flagIdMap: [Int64: Int64]
    private var noteIdMap: [Int64: Int64]
    private var workTypeIdMap: [Int64: Int64]
    private var workTypeRequestIdMap: [String: Int64] = [String: Int64]()

    private var syncChangeResults = [WorksiteSyncResult.ChangeResult]()

    private let networkWorksiteGuard = ManagedAtomic(false)
    private var _networkWorksite: NetworkWorksiteFull? = nil

    init(
        changeSetOperator: WorksiteChangeSetOperator,
        networkDataSource: CrisisCleanupNetworkDataSource,
        writeApiClient: CrisisCleanupWriteApi,
        accountData: AccountData,
        networkMonitor: NetworkMonitor,
        appEnv: AppEnv,
        syncLogger: SyncLogger,
        hasPriorUnsyncedChanges: Bool,
        networkWorksiteId: Int64,
        affiliateOrganizations: Set<Int64>,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64]
    ) {
        self.changeSetOperator = changeSetOperator
        self.networkDataSource = networkDataSource
        self.writeApiClient = writeApiClient
        self.accountData = accountData
        self.networkMonitor = networkMonitor
        self.appEnv = appEnv
        self.syncLogger = syncLogger
        self.hasPriorUnsyncedChanges = hasPriorUnsyncedChanges
        self.networkWorksiteId = networkWorksiteId
        self.affiliateOrganizations = affiliateOrganizations
        flagIdMap = flagIdLookup
        noteIdMap = noteIdLookup
        workTypeIdMap = workTypeIdLookup
    }

    private func getNetworkWorksite(_ force: Bool = false) async throws -> NetworkWorksiteFull {
        do {
            if networkWorksiteGuard.exchange(true, ordering: .sequentiallyConsistent) {
                throw GenericError("Do not process sync tasks concurrently")
            }
            defer { networkWorksiteGuard.store(false, ordering: .sequentiallyConsistent) }

            if force || _networkWorksite == nil {
                if (networkWorksiteId <= 0) {
                    fatalError("Attempted to query worksite when not yet created")
                }
                _networkWorksite = try await networkDataSource.getWorksite(networkWorksiteId)
            }
        }
        if let worksite = _networkWorksite { return worksite }
        try await ensureSyncConditions()
        throw WorksiteNotFoundException(networkWorksiteId)
    }

    private func updateWorkTypeIdMap(
        _ lookup: [String: Int64],
        _ forceQueryWorksite: Bool
    ) async throws {
        let networkWorksite = try await getNetworkWorksite(forceQueryWorksite)
        networkWorksite.newestWorkTypes.forEach { networkWorkType in
            if let localId = lookup[networkWorkType.workType] {
                workTypeIdMap[localId] = networkWorkType.id!
            }
        }
    }

    var syncResult: WorksiteSyncResult {
        let workTypeKeyMap = _networkWorksite?.newestWorkTypes
            .associate { ($0.workType, $0.id!) } ?? [:]
        return WorksiteSyncResult(
            changeResults: syncChangeResults,
            changeIds: WorksiteSyncResult.ChangeIds(
                networkWorksiteId: networkWorksiteId,
                flagIdMap: flagIdMap,
                noteIdMap: noteIdMap,
                workTypeIdMap: workTypeIdMap,
                workTypeKeyMap: workTypeKeyMap,
                workTypeRequestIdMap: workTypeRequestIdMap
            )
        )
    }

    func process(
        startingReferenceChange: SyncWorksiteChange,
        sortedChanges: [SyncWorksiteChange]
    ) async throws {
        var start = startingReferenceChange.worksiteChange.start

        let lastLoopIndex = sortedChanges.count - 1
        for (index, syncChange) in sortedChanges.enumerated() {
            let changes = hasPriorUnsyncedChanges
            ? syncChange.worksiteChange.copy { $0.start = start }
            : syncChange.worksiteChange

            let syncResult = try await syncChangeDelta(syncChange, changes)
            let hasError = syncResult.hasError
            syncChangeResults.append(
                WorksiteSyncResult.ChangeResult(
                    id: syncChange.id,
                    isSuccessful: !hasError && syncResult.isFullySynced,
                    isPartiallySuccessful: syncResult.isPartiallySynced,
                    isFail: hasError,
                    error: syncResult.primaryException
                )
            )

            hasPriorUnsyncedChanges = !syncResult.isFullySynced
            if syncResult.isFullySynced {
                start = syncChange.worksiteChange.change
            }

            appEnv.runInNonProd {
                let syncExceptionSummary = syncResult.exceptionSummary
                if syncExceptionSummary.isNotBlank {
                    syncLogger.log("Sync change exceptions.", details: syncExceptionSummary)
                }
            }

            if !syncResult.canContinueSyncing {
                return
            }

            if (syncResult.isFullySynced || syncResult.isPartiallySynced) &&
                syncResult.worksite == nil &&
                index < lastLoopIndex
            {
                _ = try await getNetworkWorksite(true)
            }
        }
    }

    private func syncChangeDelta(
        _ syncChange: SyncWorksiteChange,
        _ deltaChange: WorksiteChange
    ) async throws -> SyncChangeSetResult {
        if deltaChange.isWorkTypeTransferChange {
            return try await syncWorkTypeTransfer(
                syncChange,
                deltaChange
            )
        } else if deltaChange.isWorksiteDataChange == true {
            let isNewChange = deltaChange.start == nil || networkWorksiteId <= 0
            let changeSet = isNewChange
            ? changeSetOperator.getNewSet(deltaChange.change)
            : changeSetOperator.getChangeSet(
                base: try await getNetworkWorksite(),
                start: deltaChange.start!,
                change: deltaChange.change,
                flagIdLookup: flagIdMap,
                noteIdLookup: noteIdMap,
                workTypeIdLookup: workTypeIdMap
            )

            let isPartiallySynced = syncChange.isPartiallySynced && networkWorksiteId > 0
            return try await syncChangeSet(
                syncChange.createdAt,
                // TODO: New changes should use a constant sync ID even if previous changes are skipped
                syncChange.syncUuid,
                isPartiallySynced,
                changeSet
            )
        } else {
            syncLogger.log("Skipping unsupported change")
            return SyncChangeSetResult(
                isPartiallySynced: false,
                isFullySynced: false,
                exception: GenericError("Unsupported sync change")
            )
        }
    }

    private func syncWorkTypeTransfer(
        _ syncChange: SyncWorksiteChange,
        _ deltaChange: WorksiteChange
    ) async throws -> SyncChangeSetResult {
        var result = SyncChangeSetResult(isPartiallySynced: false, isFullySynced: false)
        let changeCreatedAt = syncChange.createdAt
        if deltaChange.requestWorkTypes?.hasValue == true {
            result = try await syncRequestWorkTypes(
                changeCreatedAt,
                deltaChange.requestWorkTypes!,
                result
            )
        } else if deltaChange.releaseWorkTypes?.hasValue == true {
            result = try await syncReleaseWorkTypes(
                changeCreatedAt,
                deltaChange.change,
                deltaChange.releaseWorkTypes!,
                result
            )
        }

        return result.copy { $0.isFullySynced = true }
    }

    private func syncChangeSet(
        _ changeCreatedAt: Date,
        _ changeSyncUuid: String,
        _ isPartiallySynced: Bool,
        _ changeSet: WorksiteChangeSet
    ) async throws -> SyncChangeSetResult {
        var result = SyncChangeSetResult(isPartiallySynced: isPartiallySynced, isFullySynced: false)
        var worksite = _networkWorksite
        do {
            if (isPartiallySynced) {
                syncLogger.log("Partially synced. Skipping core.")
            } else {
                if let changeWorksite = changeSet.worksite {
                    worksite = try await writeApiClient.saveWorksite(changeCreatedAt, changeSyncUuid, changeWorksite)
                    networkWorksiteId = worksite!.id
                    _networkWorksite = worksite

                    result = result.copy { $0.isPartiallySynced = true }

                    syncLogger.log("Synced core \(networkWorksiteId).")
                }
            }

            if ((_networkWorksite?.id ?? -1) <= 0) {
                throw WorksiteNotFoundException(networkWorksiteId)
            }

            if let isOrgMember = changeSet.isOrgMember {
                let favoriteId = worksite?.favorite?.id
                result = try await syncFavorite(changeCreatedAt, isOrgMember, favoriteId, result)
            }

            result = try await syncFlags(changeCreatedAt, changeSet.flagChanges, result)

            result = try await syncNotes(changeCreatedAt, changeSet.extraNotes, result)

            result = try await syncWorkTypes(changeCreatedAt, changeSet.workTypeChanges, result)

            result = result.copy { $0.isFullySynced = true }

            if (changeSet.hasNonCoreChanges || result.hasClaimChange) {
                worksite = try await getNetworkWorksite(true)
                result = result.copy { $0.worksite = worksite }
            }

            if (result.hasClaimChange) {
                let workTypeLocalIdLookup =
                    changeSet.workTypeChanges.associate { ($0.workType.workType, $0.localId) }
                try await updateWorkTypeIdMap(workTypeLocalIdLookup, false)
            }

        } catch {
            if let genericError = error as? GenericError {
                if genericError == NoInternetConnectionError {
                    result = result.copy { $0.isConnectedToInternet = false }
                } else if genericError == ExpiredTokenError {
                    result = result.copy { $0.isValidToken = false }
                } else {
                    result = result.copy { $0.exception = genericError }
                }
            } else {
                result = result.copy { $0.exception = error }
            }
        }

        return result
    }

    private func syncFavorite(
        _ changeAt: Date,
        _ favorite: Bool,
        _ favoriteId: Int64?,
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        do {
            if (favorite) {
                _ = try await writeApiClient.favoriteWorksite(changeAt, networkWorksiteId)
            } else {
                if (favoriteId != nil) {
                    _ = try await writeApiClient.unfavoriteWorksite(changeAt, networkWorksiteId, favoriteId!)
                }
            }

            syncLogger.log("Synced favorite.")

            return baseResult
        } catch {
            try await ensureSyncConditions()
            return baseResult.copy { $0.favoriteException = error }
        }
    }

    private func syncFlags(
        _ changeAt: Date,
        _ flagChanges: ([(Int64, NetworkFlag)], [Int64]),
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        var addFlagExceptions = [Int64: Error]()
        let (newFlags, deleteFlagIds) = flagChanges
        for (localId, flag) in newFlags {
            do {
                let syncedFlag = try await writeApiClient.addFlag(changeAt, networkWorksiteId, flag)
                flagIdMap[localId] = syncedFlag.id!
                syncLogger.log("Synced flag \(localId) (\(syncedFlag.id!)).")

            } catch {
                try await ensureSyncConditions()
                addFlagExceptions[localId] = error
            }
        }

        var deleteFlagExceptions = [Int64: Error]()
        for flagId in deleteFlagIds {
            do {
                try await writeApiClient.deleteFlag(changeAt, networkWorksiteId, flagId)
                syncLogger.log("Synced delete flag \(flagId).")
            } catch {
                try await ensureSyncConditions()
                deleteFlagExceptions[flagId] = error
            }
        }
        return baseResult.copy {
            $0.addFlagExceptions = addFlagExceptions
            $0.deleteFlagExceptions = deleteFlagExceptions
        }
    }

    private func syncNotes(
        _ changeAt: Date,
        _ notes: [(Int64, NetworkNote)],
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        var noteExceptions = [Int64: Error]()
        for (localId, note) in notes {
            if let noteContent = note.note {
                do {
                    let syncedNote =
                        try await writeApiClient.addNote(note.createdAt, networkWorksiteId, noteContent)
                    noteIdMap[localId] = syncedNote.id!
                    syncLogger.log("Synced note \(localId) (\(syncedNote.id!)).")
                } catch {
                    try await ensureSyncConditions()
                    noteExceptions[localId] = error
                }
            }
        }
        return baseResult.copy { $0.noteExceptions = noteExceptions }
    }

    private func syncWorkTypes(
        _ changeAt: Date,
        _ workTypeChanges: [WorkTypeChange],
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        var workTypeStatusExceptions = [Int64: Error]()
        var claimWorkTypes: Set<String> = []
        var unclaimWorkTypes: Set<String> = []
        for workTypeChange in workTypeChanges {
            let localId = workTypeChange.localId
            let workType = workTypeChange.workType
            if (workTypeChange.isStatusChange) {
                do {
                    let syncedWorkType =
                        try await writeApiClient.updateWorkTypeStatus(changeAt, workType.id, workType.status)
                    workTypeIdMap[localId] = syncedWorkType.id!
                    syncLogger.log("Synced work type status \(localId) (\(syncedWorkType.id!)).")
                } catch {
                    try await ensureSyncConditions()
                    workTypeStatusExceptions[localId] = error
                }
            } else if (workTypeChange.isClaimChange) {
                let isClaiming = workType.orgClaim != nil
                if (isClaiming) {
                    claimWorkTypes.insert(workType.workType)
                } else {
                    unclaimWorkTypes.insert(workType.workType)
                }
            }
        }

        var hasClaimChange = false
        let workTypeOrgLookup = try await getNetworkWorksite().newestWorkTypes
            .compactMap { $0.orgClaim == nil ? nil : ($0.workType, $0.orgClaim!) }
            .associate { $0 }

        var workTypeClaimException: Error? = nil
        let networkClaimWorkTypes = claimWorkTypes.filter { workTypeOrgLookup[$0] == nil }
        // Do not call to API with empty arrays as it may indicate all.
        if !networkClaimWorkTypes.isEmpty {
            do {
                try await writeApiClient.claimWorkTypes(
                    changeAt,
                    networkWorksiteId,
                    Array(networkClaimWorkTypes)
                )
                hasClaimChange = true
                syncLogger.log("Synced work type claim \(networkClaimWorkTypes.joined(separator: ", ")).")
            } catch {
                try await ensureSyncConditions()
                workTypeClaimException = error
            }
        }


        var workTypeUnclaimException: Error? = nil
        let networkUnclaimWorkTypes = unclaimWorkTypes.filter {
            let claimOrgId = workTypeOrgLookup[$0]
            return claimOrgId != nil && affiliateOrganizations.contains(claimOrgId!)
        }
        // Do not call to API with empty arrays as it may indicate all.
        if !networkUnclaimWorkTypes.isEmpty {
            do {
                try await writeApiClient.unclaimWorkTypes(
                    changeAt,
                    networkWorksiteId,
                    Array(networkUnclaimWorkTypes)
                )
                hasClaimChange = true
                syncLogger.log("Synced work type unclaim \(networkUnclaimWorkTypes.joined(separator: ", ")).")
            } catch {
                try await ensureSyncConditions()
                workTypeUnclaimException = error
            }
        }

        return baseResult.copy {
            $0.hasClaimChange = hasClaimChange
            $0.workTypeStatusExceptions = workTypeStatusExceptions
            $0.workTypeClaimException = workTypeClaimException
            $0.workTypeUnclaimException = workTypeUnclaimException
        }
    }

    private func syncRequestWorkTypes(
        _ changeAt: Date,
        _ transferRequest: WorkTypeTransfer,
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        let networkWorksite = try await getNetworkWorksite()
        let requestWorkTypes = networkWorksite.matchOtherOrgWorkTypes(transferRequest, affiliateOrganizations)
        if requestWorkTypes.isEmpty { return baseResult }
        do {
            try await writeApiClient.requestWorkTypes(
                changeAt,
                networkWorksite.id,
                requestWorkTypes,
                transferRequest.reason
            )

            let workTypeRequests = try await networkDataSource.getWorkTypeRequests(networkWorksiteId)
            workTypeRequests.forEach {
                workTypeRequestIdMap[$0.workType.workType] = $0.id
            }

            return baseResult
        } catch {
            try await ensureSyncConditions()
            return baseResult.copy { $0.workTypeRequestException = error }
        }
    }

    private func syncReleaseWorkTypes(
        _ changeAt: Date,
        _ worksite: WorksiteSnapshot,
        _ transferRelease: WorkTypeTransfer,
        _ baseResult: SyncChangeSetResult
    ) async throws -> SyncChangeSetResult {
        let networkWorksite = try await getNetworkWorksite()
        let releaseWorkTypes = networkWorksite.matchOtherOrgWorkTypes(transferRelease, affiliateOrganizations)
        if releaseWorkTypes.isEmpty { return baseResult }
        do {
            try await writeApiClient.releaseWorkTypes(
                changeAt,
                networkWorksite.id,
                releaseWorkTypes,
                transferRelease.reason
            )

            let workTypeLocalIdLookup = worksite.workTypes.associate {
                ($0.workType.workType, $0.localId)
            }
            try await updateWorkTypeIdMap(workTypeLocalIdLookup, true)

            return baseResult
        } catch {
            // TODO: Failure likely introduces inconsistencies on downstream changes and local state.
            //       How to manage properly and completely?
            //       Local state at this point likely has unclaimed work types.
            //       Further operations may introduce and propagate additional inconsistencies.
            try await ensureSyncConditions()
            return baseResult.copy { $0.workTypeReleaseException = error }
        }
    }

    private func ensureSyncConditions() async throws {
        // TODO: Find a reliable signal for offline state
//        if try await networkMonitor.isNotOnline.eraseToAnyPublisher().asyncFirst() {
//            throw NoInternetConnectionError
//        }
        if !accountData.areTokensValid {
            throw ExpiredTokenError
        }
    }
}

extension NetworkWorksiteFull {
    fileprivate func matchOtherOrgWorkTypes(
        _ transfer: WorkTypeTransfer,
        _ affiliateOrganizations: Set<Int64>
    ) -> [String] {
        let otherOrgClaimed = Set(
            newestWorkTypes
                .filter { $0.orgClaim != nil && !affiliateOrganizations.contains($0.orgClaim!) }
                .map { $0.workType }
        )
        return transfer.workTypes.filter { otherOrgClaimed.contains($0) }
    }
}

struct WorksiteNotFoundException: Error {
    let networkWorksiteId: Int64
    let message: String

    init(_ networkWorksiteId: Int64) {
        self.networkWorksiteId = networkWorksiteId
        message = "Worksite \(networkWorksiteId) not found/created"
    }
}

// sourcery: copyBuilder
internal struct SyncChangeSetResult {
    /**
     * Indicates syncing of core worksite data was successful
     *
     * Is not indicative of non-core data in any way.
     */
    let isPartiallySynced: Bool
    /**
     * Indicates syncing ended without aborting (with or without error)
     *
     * Abort occurs when
     * - Internet connection is lost
     * - Token becomes invalid
     *
     * Errors can be ascertained through [hasError] and exceptions.
     */
    let isFullySynced: Bool

    let worksite: NetworkWorksiteFull?
    let hasClaimChange: Bool

    let isConnectedToInternet: Bool
    let isValidToken: Bool

    let exception: Error?
    let favoriteException: Error?
    let addFlagExceptions: [Int64: Error]
    let deleteFlagExceptions: [Int64: Error]
    let noteExceptions: [Int64: Error]
    let workTypeStatusExceptions: [Int64: Error]
    let workTypeClaimException: Error?
    let workTypeUnclaimException: Error?
    let workTypeRequestException: Error?
    let workTypeReleaseException: Error?

    init(
        isPartiallySynced: Bool,
        isFullySynced: Bool,
        worksite: NetworkWorksiteFull? = nil,
        hasClaimChange: Bool = false,
        isConnectedToInternet: Bool = true,
        isValidToken: Bool = true,
        exception: Error? = nil,
        favoriteException: Error? = nil,
        addFlagExceptions: [Int64: Error] = [:],
        deleteFlagExceptions: [Int64: Error] = [:],
        noteExceptions: [Int64: Error] = [:],
        workTypeStatusExceptions: [Int64: Error] = [:],
        workTypeClaimException: Error? = nil,
        workTypeUnclaimException: Error? = nil,
        workTypeRequestException: Error? = nil,
        workTypeReleaseException: Error? = nil
    ) {
        self.isPartiallySynced = isPartiallySynced
        self.isFullySynced = isFullySynced
        self.worksite = worksite
        self.hasClaimChange = hasClaimChange
        self.isConnectedToInternet = isConnectedToInternet
        self.isValidToken = isValidToken
        self.exception = exception
        self.favoriteException = favoriteException
        self.addFlagExceptions = addFlagExceptions
        self.deleteFlagExceptions = deleteFlagExceptions
        self.noteExceptions = noteExceptions
        self.workTypeStatusExceptions = workTypeStatusExceptions
        self.workTypeClaimException = workTypeClaimException
        self.workTypeUnclaimException = workTypeUnclaimException
        self.workTypeRequestException = workTypeRequestException
        self.workTypeReleaseException = workTypeReleaseException
    }

    private var dataException: Error?
    {
        [
            exception,
            favoriteException,
            addFlagExceptions.values.first,
            deleteFlagExceptions.values.first,
            noteExceptions.values.first,
            workTypeStatusExceptions.values.first,
            workTypeClaimException,
            workTypeUnclaimException,
            workTypeRequestException,
            workTypeReleaseException,
        ]
            .compactMap { $0 }
            .first
    }

    var primaryException: Error?
    {
        if !isConnectedToInternet { return NoInternetConnectionError }
        if !isValidToken { return ExpiredTokenError }
        return dataException
    }

    var hasError: Bool { dataException != nil }

    private func summarizeExceptions(_ key: String, _ exceptions: [Int64: Error]) -> String {
        if exceptions.isNotEmpty {
            let summary = exceptions
                .map { "  \($0.key): \($0.value.localizedDescription)" }
                .joined(separator: "\n")
            return "\(key)\n\(summary)"
        }
        return ""
    }

    var exceptionSummary: String {
        [
            exception == nil ? nil : "Overall \(exception!.localizedDescription)",
            favoriteException?.prefixMessage("Favorite"),
            summarizeExceptions("Flags", addFlagExceptions),
            summarizeExceptions("Delete flags", deleteFlagExceptions),
            summarizeExceptions("Notes", noteExceptions),
            summarizeExceptions("Work type status", workTypeStatusExceptions),
            workTypeClaimException?.prefixMessage("Claim work types"),
            workTypeUnclaimException?.prefixMessage("Unclaim work types"),
            workTypeRequestException?.prefixMessage("Request work types"),
            workTypeReleaseException?.prefixMessage("Release work types"),
        ]
            .compactMap { $0?.isNotBlank == true ? $0 : nil }
            .joined(separator: "\n")
    }

    var canContinueSyncing: Bool {
        isConnectedToInternet && isValidToken
    }
}

extension Error {
    fileprivate var errorMessage: String {
        (self as? CrisisCleanupNetworkError)?.errors.first?.messages?.joined(separator: ", ") ?? localizedDescription
    }

    fileprivate func prefixMessage(_ prefix: String) -> String {
        "\(prefix): \(errorMessage)"
    }
}
