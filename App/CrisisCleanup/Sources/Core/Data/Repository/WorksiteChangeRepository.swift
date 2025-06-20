import Atomics
import Combine
import Foundation
import SwiftUI

public protocol WorksiteChangeRepository {
    var worksiteChangeCount: Int { get }

    var syncingWorksiteIds: any Publisher<Set<Int64>, Never> { get }

    var streamWorksitesPendingSync: any Publisher<[WorksitePendingSync], Never> { get }

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
    ) async throws -> Bool

    func syncWorksites(_ syncWorksiteCount: Int) async

    /**
     * - Returns: Worksite ID containing the photo if found or -1 otherwise
     */
    func saveDeletePhoto(_ fileId: Int64) throws -> Int64

    func trySyncWorksite(_ worksiteId: Int64) async -> Bool

    func syncUnattemptedWorksite(_ worksiteId: Int64) async

    func syncWorksiteMedia() async throws -> Bool
}

extension WorksiteChangeRepository {
    func saveWorkTypeTransferOne(
        worksite: Worksite,
        organizationId: Int64,
        requestReason: String = "",
        requests: [String] = [],
        releaseReason: String = "",
        releases: [String] = []
    ) async throws -> Bool {
        try await saveWorkTypeTransfer(
            worksite: worksite,
            organizationId: organizationId,
            requestReason: requestReason,
            requests: requests,
            releaseReason: releaseReason,
            releases: releases
        )
    }

    func syncWorksites() async {
        await syncWorksites(0)
    }
}

internal let MaxSyncTries = 3

class CrisisCleanupWorksiteChangeRepository: WorksiteChangeRepository {
    private let worksiteDao: WorksiteDao
    private let worksiteChangeDao: WorksiteChangeDao
    private let worksiteFlagDao: WorksiteFlagDao
    private let worksiteNoteDao: WorksiteNoteDao
    private let workTypeDao: WorkTypeDao
    private let localImageDao: LocalImageDao
    private let localFileCache: LocalFileCache
    private let worksiteChangeSyncer: WorksiteChangeSyncer
    private let worksitePhotoChangeSyncer: WorksitePhotoChangeSyncer
    private let accountDataRepository: AccountDataRepository
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let worksitesRepository: WorksitesRepository
    private let organizationsRepository: OrganizationsRepository
    private let localImageRepository: LocalImageRepository
    private let accountEventBus: AccountEventBus
    private let worksiteInteractor: WorksiteInteractor
    private let appEnv: AppEnv
    private let syncLoggerFactory: SyncLoggerFactory
    private var syncLogger: SyncLogger
    private let appLogger: AppLogger

    var worksiteChangeCount: Int {
        worksiteChangeDao.getWorksiteChangeCount()
    }

    private let syncingWorksiteIdsLock = NSLock()
    private var _syncingWorksiteIds = Set<Int64>()
    private let syncingWorksiteIdsSubject = CurrentValueSubject<Set<Int64>, Never>([])
    let syncingWorksiteIds: any Publisher<Set<Int64>, Never>

    private let syncWorksiteGuard = ManagedAtomic(false)

    var streamWorksitesPendingSync: any Publisher<[WorksitePendingSync], Never> {
        worksiteChangeDao.streamWorksitesPendingSync()
    }

    private let accountDataPublisher: AnyPublisher<AccountData, Never>

    init(
        worksiteDao: WorksiteDao,
        worksiteChangeDao: WorksiteChangeDao,
        worksiteFlagDao: WorksiteFlagDao,
        worksiteNoteDao: WorksiteNoteDao,
        workTypeDao: WorkTypeDao,
        localImageDao: LocalImageDao,
        localFileCache: LocalFileCache,
        worksiteChangeSyncer: WorksiteChangeSyncer,
        worksitePhotoChangeSyncer: WorksitePhotoChangeSyncer,
        accountDataRepository: AccountDataRepository,
        networkDataSource: CrisisCleanupNetworkDataSource,
        worksitesRepository: WorksitesRepository,
        organizationsRepository: OrganizationsRepository,
        localImageRepository: LocalImageRepository,
        accountEventBus: AccountEventBus,
        worksiteInteractor: WorksiteInteractor,
        appEnv: AppEnv,
        syncLoggerFactory: SyncLoggerFactory,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteDao = worksiteDao
        self.worksiteChangeDao = worksiteChangeDao
        self.worksiteFlagDao = worksiteFlagDao
        self.worksiteNoteDao = worksiteNoteDao
        self.workTypeDao = workTypeDao
        self.localImageDao = localImageDao
        self.localFileCache = localFileCache
        self.worksiteChangeSyncer = worksiteChangeSyncer
        self.worksitePhotoChangeSyncer = worksitePhotoChangeSyncer
        self.accountDataRepository = accountDataRepository
        self.networkDataSource = networkDataSource
        self.worksitesRepository = worksitesRepository
        self.organizationsRepository = organizationsRepository
        self.localImageRepository = localImageRepository
        self.accountEventBus = accountEventBus
        self.worksiteInteractor = worksiteInteractor
        self.appEnv = appEnv
        self.syncLoggerFactory = syncLoggerFactory
        syncLogger = syncLoggerFactory.getLogger("")
        appLogger = loggerFactory.getLogger("worksite-sync")

        syncingWorksiteIds = syncingWorksiteIdsSubject

        accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()
    }

    func saveWorksiteChange(
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        primaryWorkType: WorkType,
        organizationId: Int64
    ) async throws -> Int64 {
        do {
            let id = try await worksiteChangeDao.saveChange(
                worksiteStart: worksiteStart,
                worksiteChange: worksiteChange,
                primaryWorkType: primaryWorkType,
                organizationId: organizationId
            )
            worksiteInteractor.onCaseChanged(worksiteChange.incidentId, id)
            return id
        } catch {
            appLogger.logError(error)
            throw error
        }
    }

    func saveWorkTypeTransfer(worksite: Worksite, organizationId: Int64, requestReason: String, requests: [String], releaseReason: String, releases: [String]) async throws -> Bool {
        guard !worksite.isNew && organizationId > 0 else {
            return false
        }

        if requestReason.isNotBlank && requests.isNotEmpty {
            try await worksiteChangeDao.saveWorkTypeRequests(
                worksite,
                organizationId,
                requestReason,
                requests
            )
            worksiteInteractor.onCaseChanged(worksite.incidentId, worksite.id)
            return true
        }

        if releaseReason.isNotBlank && releases.isNotEmpty {
            try await worksiteChangeDao.saveWorkTypeReleases(
                worksite,
                organizationId,
                releaseReason,
                releases
            )
            return true
        }

        return false
    }

    func syncWorksites(_ syncWorksiteCount: Int) async {
        if !syncWorksiteGuard.exchange(true, ordering: .sequentiallyConsistent) {
            var worksiteId: Int64
            do {
                defer { syncWorksiteGuard.store(false, ordering: .sequentiallyConsistent) }

                var previousWorksiteId: Int64 = 0
                var syncCounter = 0
                let syncCountLimit = syncWorksiteCount < 1 ? 20 : syncWorksiteCount
                while syncCounter < syncCountLimit {
                    syncCounter += 1

                    var worksiteIds = try worksiteDao.getLocallyModifiedWorksites(1)
                    if worksiteIds.isEmpty {
                        worksiteIds = try worksiteChangeDao.getWorksitesPendingSync(1)
                        if worksiteIds.isEmpty {
                            break
                        }
                    }
                    worksiteId = worksiteIds.first!

                    if worksiteId == previousWorksiteId {
                        let saveFailCount = try worksiteChangeDao.getSaveFailCount(worksiteId)
                        if saveFailCount > 0
                        {
                            break
                        }
                    }
                    previousWorksiteId = worksiteId

                    _ = try await trySyncWorksite(worksiteId, true)

                    try Task.checkCancellation()
                    _ = try await UIApplication.shared.checkTimeout(10)
                }
            } catch {
                // TODO: Indicate error with notification
            }
        }
    }

    func saveDeletePhoto(_ fileId: Int64) throws -> Int64 {
        try worksiteChangeDao.saveDeletePhoto(fileId)
    }

    func trySyncWorksite(_ worksiteId: Int64) async -> Bool {
        do {
            return try await trySyncWorksite(worksiteId, false)
        }
        catch {}
        return false
    }

    func syncUnattemptedWorksite(_ worksiteId: Int64) async {
        do {
            if try worksiteChangeDao.getSaveFailCount(worksiteId) == 0 {
                _ = try await trySyncWorksite(worksiteId, false)
            }
        }
        catch {}
    }

    private func trySyncWorksite(
        _ worksiteId: Int64,
        _ rethrowError: Bool
    ) async throws -> Bool {
        let accountData = try await accountDataPublisher.asyncFirst()
        if !accountData.areTokensValid {
            syncLogger.log("Not attempting. Invalid account token.")
            return false
        }

        do {
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

            defer {
                if performSync {
                    syncingWorksiteIdsLock.withLock {
                        _syncingWorksiteIds.remove(worksiteId)
                        syncingWorksiteIdsSubject.value = Set(_syncingWorksiteIds)
                    }
                }

                syncLogger.flush()
            }

            try await self.syncWorksite(worksiteId)
        } catch {
            var unhandledException: Error? = nil
            if let genericError = error as? GenericError {
                if genericError != NoInternetConnectionError {
                    unhandledException = genericError
                }
            } else {
                unhandledException = error
            }
            if let endError = unhandledException {
                self.appLogger.logError(endError)

                if rethrowError {
                    throw endError
                } else {
                    // TODO: Indicate error visually
                    syncLogger.log("Sync failed", details: endError.localizedDescription)
                }
            }
        }

        return true
    }

    private func syncWorksite(_ worksiteId: Int64) async throws {
        syncLogger = syncLoggerFactory.getLogger("syncing-worksite-\(worksiteId)-\(Date.now.timeIntervalSince1970.rounded())")

        var syncException: Error? = nil

        let sortedChanges = try worksiteChangeDao.getOrdered(worksiteId)
        if sortedChanges.isNotEmpty {
            syncLogger.log("\(sortedChanges.count) changes.")

            let newestChange = sortedChanges.last!
            let newestChangeOrgId = newestChange.organizationId
            let accountData = try await accountDataPublisher.asyncFirst()
            let organizationId = accountData.org.id
            if newestChangeOrgId != organizationId {
                syncLogger.log("Not syncing. Org mismatch \(organizationId) != \(newestChangeOrgId).")
                // TODO: Insert notice that newest change of worksite was with a different organization
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

        let isFullySynced = try await worksiteDao.onSyncEnd(worksiteId, MaxSyncTries, syncLogger)
        if isFullySynced {
            syncLogger.clear()
            syncLogger.log("Worksite fully synced.")
        } else {
            let caseNumber = syncNetworkWorksite?.caseNumber ?? "?"
            syncLogger.log("Unsynced data exists for \(caseNumber).")

        }

        if let syncWorksite = syncNetworkWorksite,
           incidentId > 0 {
            _ = try await worksitesRepository.syncNetworkWorksite(syncWorksite)
            worksiteInteractor.onCaseChanged(incidentId, worksiteId)
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
            let affiliateOrganizations = organizationsRepository.getOrganizationAffiliateIds(
                organizationId,
                addOrganizationId: true
            )
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

            try await worksiteChangeDao.updateSyncIds(
                worksiteId: worksiteId,
                organizationId: organizationId,
                ids: syncResult.changeIds
            )
            try await worksiteChangeDao.updateSyncChanges(
                worksiteId: worksiteId,
                changeResults: syncResult.changeResults,
                maxSyncAttempts: MaxSyncTries
            )

            try syncResult.changeResults
                .compactMap { $0.error }
                .forEach {
                    if let genericError = $0 as? GenericError,
                       genericError == NoInternetConnectionError ||
                        genericError == ExpiredTokenError {
                        throw genericError
                    }
                }
        } else {
            syncLogger.log("Not syncing. Worksite \(newestChange.worksiteId) change is not syncable.")
            // Complexity is not worth retrying at this point.
            // TODO: How to handle gracefully?
            //       Wait for user modification, intervention, or prompt?
        }
    }

    private func syncPhotoChanges(_ worksiteId: Int64) async {
        do {
            let deleteFileIds = try localImageDao.getDeletedPhotoFileIds(worksiteId)
            if deleteFileIds.isNotEmpty {
                let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
                try await worksitePhotoChangeSyncer.deletePhotoFiles(networkWorksiteId, deleteFileIds)
                syncLogger.log("Deleted photos", details: deleteFileIds.map { String($0) }.joined(separator: ", "))
            }
        } catch {
            syncLogger.log("Delete photo error", details: error.localizedDescription)
        }
    }

    func syncWorksiteMedia() async throws -> Bool {
        let worksitesWithImages = localImageDao.getUploadImageWorksiteIds()
        var isSyncedAll = true
        for worksiteImageUpload in worksitesWithImages {
            try Task.checkCancellation()
            _ = try await UIApplication.shared.checkTimeout(15)

            let worksiteId = worksiteImageUpload.worksiteId
            let syncCount = try await localImageRepository.syncWorksiteMedia(worksiteId)
            if syncCount > 0 {
                try await syncWorksite(worksiteId)
            }
            let unsyncedCount = worksiteImageUpload.count - syncCount
            isSyncedAll = isSyncedAll && unsyncedCount == 0
        }

        let remainingFiles = Set(localImageDao.getPendingLocalImageFileNames())
        localFileCache.deleteUnspecifiedFiles(remainingFiles)

        return isSyncedAll
    }
}
