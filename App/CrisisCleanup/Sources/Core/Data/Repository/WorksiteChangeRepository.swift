import Combine
import Foundation

public protocol WorksiteChangeRepository {
    var syncingWorksiteIds: any Publisher<Set<Int64>, Never> { get }

    var streamWorksitesPendingSync: any Publisher<[Worksite], Never> { get }

    func saveWorksiteChange(
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        primaryWorkType: WorkType,
        organizationId: Int64
    ) async throws -> Int64

    func saveWorkTypeTransfer(
        worksite: Worksite,
        organizationId: Int64,
        requestReason: String,
        requests: [String],
        releaseReason: String,
        releases: [String]
    ) async -> Bool

    /**
     * - Returns: TRUE if sync was attempted or FALSE otherwise
     */
    func syncWorksites(_ syncWorksiteCount: Int) async -> Bool

    func saveDeletePhoto(_ fileId: Int64) async -> Int64

    func trySyncWorksite(_ worksiteId: Int64) async -> Bool

    func syncWorksiteMedia() async -> Bool
}

extension WorksiteChangeRepository {
    func saveWorkTypeTransferOne(
        worksite: Worksite,
        organizationId: Int64,
        requestReason: String = "",
        requests: [String] = [],
        releaseReason: String = "",
        releases: [String] = []
    ) async -> Bool {
        await saveWorkTypeTransfer(
            worksite: worksite,
            organizationId: organizationId,
            requestReason: requestReason,
            requests: requests,
            releaseReason: releaseReason,
            releases: releases
        )
    }

    func syncWorksites() async -> Bool {
        await syncWorksites(0)
    }
}

private let MaxSyncTries = 3

class CrisisCleanupWorksiteChangeRepository: WorksiteChangeRepository {
    private let worksiteDao: WorksiteDao
    private let worksiteChangeDao: WorksiteChangeDao
    private let worksiteFlagDao: WorksiteFlagDao
    private let worksiteNoteDao: WorksiteNoteDao
    private let workTypeDao: WorkTypeDao
    // private let localImageDao: LocalImageDao
    private let worksiteChangeSyncer: WorksiteChangeSyncer
    // private let worksitePhotoChangeSyncer: WorksitePhotoChangeSyncer
    private let accountDataRepository: AccountDataRepository
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let worksitesRepository: WorksitesRepository
     private let organizationsRepository: OrganizationsRepository
    // private let localImageRepository: LocalImageRepository
    private let authEventBus: AuthEventBus
    private let appEnv: AppEnv
    private let syncLoggerFactory: SyncLoggerFactory
    private var syncLogger: SyncLogger
    private let appLogger: AppLogger

    private let syncingWorksiteIdsLock = NSLock()
    private var _syncingWorksiteIds = Set<Int64>()
    private let syncingWorksiteIdsSubject = CurrentValueSubject<Set<Int64>, Never>([])
    let syncingWorksiteIds: any Publisher<Set<Int64>, Never>

    private let streamWorksitesPendingSyncSubject = CurrentValueSubject<[Worksite], Never>([])
    let streamWorksitesPendingSync: any Publisher<[Worksite], Never>

    private let isNotOnlinePublisher: AnyPublisher<Bool, Never>
    private let accountDataPublisher: AnyPublisher<AccountData, Never>

    init(
        worksiteDao: WorksiteDao,
        worksiteChangeDao: WorksiteChangeDao,
        worksiteFlagDao: WorksiteFlagDao,
        worksiteNoteDao: WorksiteNoteDao,
        workTypeDao: WorkTypeDao,
        worksiteChangeSyncer: WorksiteChangeSyncer,
        accountDataRepository: AccountDataRepository,
        networkDataSource: CrisisCleanupNetworkDataSource,
        worksitesRepository: WorksitesRepository,
        organizationsRepository: OrganizationsRepository,
        authEventBus: AuthEventBus,
        networkMonitor: NetworkMonitor,
        appEnv: AppEnv,
        syncLoggerFactory: SyncLoggerFactory,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteDao = worksiteDao
        self.worksiteChangeDao = worksiteChangeDao
        self.worksiteFlagDao = worksiteFlagDao
        self.worksiteNoteDao = worksiteNoteDao
        self.workTypeDao = workTypeDao
        self.worksiteChangeSyncer = worksiteChangeSyncer
        self.accountDataRepository = accountDataRepository
        self.networkDataSource = networkDataSource
        self.worksitesRepository = worksitesRepository
        self.organizationsRepository = organizationsRepository
        self.authEventBus = authEventBus
        self.appEnv = appEnv
        self.syncLoggerFactory = syncLoggerFactory
        syncLogger = syncLoggerFactory.getLogger("")
        appLogger = loggerFactory.getLogger("worksite-sync")

        syncingWorksiteIds = syncingWorksiteIdsSubject
        streamWorksitesPendingSync = streamWorksitesPendingSyncSubject

        isNotOnlinePublisher = networkMonitor.isNotOnline.eraseToAnyPublisher()
        accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()
    }

    func saveWorksiteChange(
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        primaryWorkType: WorkType,
        organizationId: Int64
    ) async throws -> Int64 {
        do {
            return try await worksiteChangeDao.saveChange(
                worksiteStart: worksiteStart,
                worksiteChange: worksiteChange,
                primaryWorkType: primaryWorkType,
                organizationId: organizationId
            )
        } catch {
            appLogger.logError(error)
            throw error
        }
    }

    func saveWorkTypeTransfer(worksite: Worksite, organizationId: Int64, requestReason: String, requests: [String], releaseReason: String, releases: [String]) async -> Bool {
        // TODO: Do
        false
    }

    func syncWorksites(_ syncWorksiteCount: Int) async -> Bool {
        // TODO: Do
        false
    }

    func saveDeletePhoto(_ fileId: Int64) async -> Int64 {
        // TODO: Do
        0
    }

    func trySyncWorksite(_ worksiteId: Int64) async -> Bool {
        do {
            return try await trySyncWorksite(worksiteId, false)
        }
        catch {}
        return false
    }

    private func trySyncWorksite(
        _ worksiteId: Int64,
        _ rethrowError: Bool
    ) async throws -> Bool {
        if try await isNotOnlinePublisher.asyncFirst() {
            syncLogger.log("Not attempting. No internet connection.")
            return false
        }

        let accountData = try await accountDataPublisher.asyncFirst()
        if accountData.areTokensValid {
            syncLogger.log("Not attempting. Invalid account token.")
            return false
        }

        do {
            defer {
                syncingWorksiteIdsLock.withLock {
                    _syncingWorksiteIds.remove(worksiteId)
                    syncingWorksiteIdsSubject.value = Set(_syncingWorksiteIds)
                }

                syncLogger.flush()
            }

            let performSync = syncingWorksiteIdsLock.withLock {
                if _syncingWorksiteIds.contains(worksiteId) {
                    syncLogger.log("Not syncing. Currently being synced.")
                    return false
                }
                _syncingWorksiteIds.insert(worksiteId)
                syncingWorksiteIdsSubject.value = Set(_syncingWorksiteIds)
                return true
            }
            if !performSync {
                return false
            }

            try await self.syncWorksite(worksiteId)
        } catch {
            var unhandledException: Error? = nil
            if error is NoInternetConnectionError {}
            else {
                unhandledException = error
            }
            if let endError = unhandledException {
                self.appLogger.logError(endError)

                if rethrowError {
                    throw endError
                } else {
                    // TODO Indicate error visually
                    syncLogger.log("Sync failed", details: endError.localizedDescription)
                }
            }
        }

        return true
    }

    private func syncWorksite(_ worksiteId: Int64) async throws {
        syncLogger = syncLoggerFactory.getLogger("syncing-worksite-\(worksiteId)-\(Date.now.timeIntervalSince1970.rounded())")

        var syncException: Error? = nil

        let sortedChanges = worksiteChangeDao.getOrdered(worksiteId)
        if sortedChanges.isNotEmpty {
            syncLogger.log("\(sortedChanges.count) changes.")

            let newestChange = sortedChanges.last!
            let newestChangeOrgId = newestChange.organizationId
            let accountData = try await accountDataPublisher.asyncFirst()
            let organizationId = accountData.org.id
            if newestChangeOrgId != organizationId {
                syncLogger.log("Not syncing. Org mismatch \(organizationId) != \(newestChangeOrgId).")
                // TODO Insert notice that newest change of worksite was with a different organization
                return
            }

            syncLogger.log("Sync changes starting.")

            let worksiteChanges = sortedChanges.map { $0.asExternalModel(MaxSyncTries) }
            do {
                try await self.syncWorksiteChanges(worksiteChanges)
            } catch {
                syncException = error
            }

            syncLogger.log("Sync changes over.")
        }

        await syncPhotoChanges(worksiteId)

        // TODO: There is a possibility all changes have been synced but there is still unsynced accessory data.
        //       Try to sync in isolation, create a new change, or create notice with options to take action.

        // These fetches are split from the save later because WorksiteDaoPlus.onSyncEnd]
        // must run first as the [worksite_root.is_local_modified] value matters.
        var incidentId = Int64(0)
        var syncNetworkWorksite: NetworkWorksiteFull? = nil
        let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
        if networkWorksiteId > 0 {
            do {
                syncNetworkWorksite = try await networkDataSource.getWorksite(networkWorksiteId)
                incidentId = worksiteDao.getIncidentId(worksiteId)
            } catch {
                syncLogger.log("Worksite sync end fail \(error.localizedDescription)")
            }
        }

        let isFullySynced = try await worksiteDao.onSyncEnd(worksiteId)
        if isFullySynced {
            syncLogger.clear()
            syncLogger.log("Worksite fully synced.")
        } else {
            syncLogger.log("Unsynced data exists.")
        }

        if let syncWorksite = syncNetworkWorksite,
           incidentId > 0 {
            _ = try await worksitesRepository.syncNetworkWorksite(syncWorksite)
        }

        if let e = syncException { throw e }
    }

    // TODO: Complete test coverage
    private func syncWorksiteChanges(_ sortedChanges: [SavedWorksiteChange]) async throws {
        if sortedChanges.isEmpty {
            return
        }

        var startingSyncIndex = sortedChanges.count
        while (startingSyncIndex > 0) {
            if sortedChanges[startingSyncIndex - 1].isArchived {
                break
            }
            startingSyncIndex -= 1
        }

        var oldestReferenceChangeIndex = max(startingSyncIndex - 1, 0)
        while oldestReferenceChangeIndex > 0 {
            if sortedChanges[oldestReferenceChangeIndex].isSynced {
                break
            }
            oldestReferenceChangeIndex -= 1
        }
        let oldestReferenceChange = sortedChanges[oldestReferenceChangeIndex]

        let hasSnapshotChanges = startingSyncIndex < sortedChanges.count
        let newestChange = sortedChanges.last!
        if hasSnapshotChanges || !newestChange.isArchived {
            let syncChanges =
            hasSnapshotChanges ? Array(sortedChanges[startingSyncIndex..<sortedChanges.count])
            : [newestChange]
            let hasPriorUnsyncedChanges = startingSyncIndex > oldestReferenceChangeIndex + 1
            let worksiteId = newestChange.worksiteId
            let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
            let flagIdLookup = try worksiteFlagDao.getNetworkedIdMap(worksiteId).asLookup()
            let noteIdLookup = try worksiteNoteDao.getNetworkedIdMap(worksiteId).asLookup()
            let workTypeIdLookup = try workTypeDao.getNetworkedIdMap(worksiteId).asLookup()
            let accountData = try await accountDataPublisher.asyncFirst()
            let organizationId = accountData.org.id
            let affiliateOrganizations =
                organizationsRepository.getOrganizationAffiliateIds(organizationId)
            let syncResult = try await worksiteChangeSyncer.sync(
                accountData,
                oldestReferenceChange,
                syncChanges,
                hasPriorUnsyncedChanges,
                networkWorksiteId,
                flagIdLookup: flagIdLookup,
                noteIdLookup: noteIdLookup,
                workTypeIdLookup: workTypeIdLookup,
                affiliateOrganizations: affiliateOrganizations,
                syncLogger: syncLogger
            )

            appEnv.runInNonProd {
                syncLogger.log(
                    "Sync change results",
                    details: syncResult.getSummary(sortedChanges.count)
                )
            }

            worksiteChangeDao.updateSyncIds(
                worksiteId: worksiteId,
                organizationId: organizationId,
                ids: syncResult.changeIds
            )
            worksiteChangeDao.updateSyncChanges(
                worksiteId: worksiteId,
                changeResults: syncResult.changeResults,
                maxSyncAttempts: MaxSyncTries
            )

            try syncResult.changeResults.map { $0.error }
                .filter { $0 != nil }
                .forEach {
                    if $0 is NoInternetConnectionError ||
                        $0 is ExpiredTokenError {
                        throw $0!
                    }
                }
        } else {
            syncLogger.log("Not syncing. Worksite \(newestChange.worksiteId) change is not syncable.")
            // TODO Not worth retrying at this point.
            //      How to handle gracefully?
            //      Wait for user modification, intervention, or prompt?
        }
    }

    private func syncPhotoChanges(_ worksiteId: Int64) async {
        // TODO: Finish
//        do {
//            let (networkWorksiteId, deleteFileIds) =
//                localImageDao.getDeletedPhotoNetworkFileIds(worksiteId)
//            if deleteFileIds.isNotEmpty() {
//                worksitePhotoChangeSyncer.deletePhotoFiles(networkWorksiteId, deleteFileIds)
//                syncLogger.log("Deleted photos", deleteFileIds.joinToString(", "))
//            }
//        } catch {
//            syncLogger.log("Delete photo error", error.localizedDescription)
//        }
    }

    func syncWorksiteMedia() async -> Bool {
        // TODO: Do
        false
    }
}

struct NoInternetConnectionError : Error {
    let message = "No internet"
}
