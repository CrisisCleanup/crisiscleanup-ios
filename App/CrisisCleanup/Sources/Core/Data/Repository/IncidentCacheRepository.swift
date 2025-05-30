import Combine
import CoreLocation
import Foundation

public protocol IncidentCacheRepository {
    var isSyncingActiveIncident: any Publisher<Bool, Never> { get }
    var cacheStage: any Publisher<IncidentCacheStage, Never> { get }

    var cachePreferences: any Publisher<IncidentWorksitesCachePreferences, Never> { get }

    func streamSyncStats(_ incidentId: Int64) -> any Publisher<IncidentDataSyncParameters?, Never>

    /**
     *  Returns: TRUE when plan is accepted or FALSE otherwise (already queued or unable to cancel ongoing)
     */
    func submitPlan(
        overwriteExisting: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheWorksitesAdditional: Bool,
        restartCacheCheckpoint: Bool,
        planTimeout: TimeInterval,
    ) async -> Bool

    func sync() async throws -> SyncResult

    func resetIncidentSyncStats(_ incidentId: Int64) throws

    func updateCachePreferenes(_ preferences: IncidentWorksitesCachePreferences)
}

extension IncidentCacheRepository {
    func submitPlan(
        overwriteExisting: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheWorksitesAdditional: Bool,
        restartCacheCheckpoint: Bool
    ) async -> Bool {
        await submitPlan(
            overwriteExisting: overwriteExisting,
            forcePullIncidents: forcePullIncidents,
            cacheSelectedIncident: cacheSelectedIncident,
            cacheActiveIncidentWorksites: cacheActiveIncidentWorksites,
            cacheWorksitesAdditional: cacheWorksitesAdditional,
            restartCacheCheckpoint: restartCacheCheckpoint,
            planTimeout: 9.seconds
        )
    }
}

class IncidentWorksitesCacheRepository: IncidentCacheRepository, IncidentDataPullReporter {
    private let accountDataRefresher: AccountDataRefresher
    private let incidentsRepository: IncidentsRepository
    private let appPreferences: AppPreferencesDataSource
    private let syncParameterDao: IncidentDataSyncParameterDao
    private let incidentCachePreferences: IncidentCachePreferencesDataSource
    private let locationProvider: LocationManager
    private let locationBounder: IncidentLocationBounder
    private let incidentMapTracker: IncidentMapTracker
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let worksitesRepository: WorksitesRepository
    private let worksiteDao: WorksiteDao
    private let speedMonitor: DataDownloadSpeedMonitor
    private let networkMonitor: NetworkMonitor
    private let syncLogger: SyncLogger
    private let translator: KeyTranslator
    private let appEnv: AppEnv
    private let appLogger: AppLogger

    private var isNetworkUnmetered: Bool {
        networkMonitor.isInternetConnectedUnmetered
    }

    private let incidentDataPullStatsSubject = CurrentValueSubject<IncidentDataPullStats, Never>(IncidentDataPullStats())
    var incidentDataPullStats: any Publisher<IncidentDataPullStats, Never>

    private let onIncidentDataPullCompleteSubject = CurrentValueSubject<Int64, Never>(EmptyIncident.id)
    var onIncidentDataPullComplete: any Publisher<Int64, Never>

    private let syncPlanLock = NSRecursiveLock()
    private var submittedSyncPlan = EmptySyncPlan

    private let planSubmissionCountSubject = CurrentValueSubject<Int, Never>(0)
    private let planSubmissionCounter = AtomicInt()

    private let syncingIncidentId = CurrentValueSubject<Int64, Never>(EmptyIncident.id)
    var isSyncingActiveIncident: any Publisher<Bool, Never>

    private let cacheStageSubject = CurrentValueSubject<IncidentCacheStage, Never>(.inactive)
    var cacheStage: any Publisher<IncidentCacheStage, Never>

    var cachePreferences: any Publisher<IncidentWorksitesCachePreferences, Never>

    init(
        accountDataRefresher: AccountDataRefresher,
        incidentsRepository: IncidentsRepository,
        appPreferences: AppPreferencesDataSource,
        syncParameterDao: IncidentDataSyncParameterDao,
        incidentCachePreferences: IncidentCachePreferencesDataSource,
        incidentSelector: IncidentSelector,
        locationProvider: LocationManager,
        locationBounder: IncidentLocationBounder,
        incidentMapTracker: IncidentMapTracker,
        networkDataSource: CrisisCleanupNetworkDataSource,
        worksitesRepository: WorksitesRepository,
        worksiteDao: WorksiteDao,
        speedMonitor: DataDownloadSpeedMonitor,
        networkMonitor: NetworkMonitor,
        syncLogger: SyncLogger,
        translator: KeyTranslator,
        appEnv: AppEnv,
        appLoggerFactory: AppLoggerFactory
    ) {
        self.accountDataRefresher = accountDataRefresher
        self.incidentsRepository = incidentsRepository
        self.appPreferences = appPreferences
        self.syncParameterDao = syncParameterDao
        self.incidentCachePreferences = incidentCachePreferences
        self.locationProvider = locationProvider
        self.locationBounder = locationBounder
        self.incidentMapTracker = incidentMapTracker
        self.networkDataSource = networkDataSource
        self.worksitesRepository = worksitesRepository
        self.worksiteDao = worksiteDao
        self.speedMonitor = speedMonitor
        self.networkMonitor = networkMonitor
        self.syncLogger = syncLogger
        self.translator = translator
        self.appEnv = appEnv
        appLogger = appLoggerFactory.getLogger("sync")

        incidentDataPullStats = incidentDataPullStatsSubject
        onIncidentDataPullComplete = onIncidentDataPullCompleteSubject

        let isSyncingData = cacheStageSubject.map {
            $0.isSyncingStage
        }

        let isSyncingInitialIncidents = Publishers.CombineLatest(
            syncingIncidentId,
            cacheStageSubject,
        )
            .map { (syncingId, cacheStage) in
                syncingId == EmptyIncident.id && cacheStage == .incidents
            }

        let isSyncingMatchingIncident = Publishers.CombineLatest3(
            isSyncingData.eraseToAnyPublisher(),
            incidentSelector.incidentId.eraseToAnyPublisher(),
            syncingIncidentId,
        )
            .map { (isSyncing, incidentId, syncingId) in
                isSyncing && incidentId == syncingId
            }
        isSyncingActiveIncident = Publishers.CombineLatest3(
            isSyncingMatchingIncident,
            planSubmissionCountSubject,
            isSyncingInitialIncidents,
        )
        .map { (isSyncingMatching, submissionCount, isSyncingInitial) in
            isSyncingMatching ||
            submissionCount > 0 ||
            isSyncingInitial
        }

        cacheStage = cacheStageSubject
        cachePreferences = incidentCachePreferences.preferences
    }

    func streamSyncStats(_ incidentId: Int64) -> any Publisher<IncidentDataSyncParameters?, Never> {
        syncParameterDao.streamIncidentDataSyncParameters(incidentId)
            .assertNoFailure()
    }

    private func getIncidents() async -> [IncidentIdNameType] {
        await incidentsRepository.getIncidentsList()
    }

    func submitPlan(
        overwriteExisting: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheWorksitesAdditional: Bool,
        restartCacheCheckpoint:
        Bool, planTimeout: TimeInterval
    ) async -> Bool {
        do {
            planSubmissionCountSubject.value = planSubmissionCounter.incrementAndGet()

            defer {
                planSubmissionCountSubject.value = planSubmissionCounter.decrementAndGet()
            }

            let incidentIds: Set<Int64>
            let selectedIncidentId: Int64
            do {
                let incidents = await getIncidents()
                incidentIds = Set(incidents.map { $0.id })

                let preferencesPublisher = appPreferences.preferences.eraseToAnyPublisher()
                selectedIncidentId = try await preferencesPublisher.asyncFirst().selectedIncidentId
            } catch {
                appLogger.logError(error)
                return false
            }

            let isIncidentCached = incidentIds.contains(selectedIncidentId)

            if !incidentIds.isEmpty,
               !isIncidentCached,
               selectedIncidentId == EmptyIncident.id,
               !forcePullIncidents
            {
                return false
            }

            let proposedPlan = IncidentDataSyncPlan(
                incidentId: selectedIncidentId,
                syncIncidents: forcePullIncidents || !isIncidentCached,
                syncSelectedIncident: cacheSelectedIncident || !isIncidentCached,
                syncActiveIncidentWorksites: cacheActiveIncidentWorksites,
                syncWorksitesAdditional: cacheWorksitesAdditional,
                restartCache: restartCacheCheckpoint
            )

            return syncPlanLock.withLock {
                var isRedundant = false

                if !overwriteExisting,
                   !proposedPlan.syncIncidents,
                   !restartCacheCheckpoint {
                    with(submittedSyncPlan) { submitted in
                        if selectedIncidentId == submitted.incidentId,
                           submitted.timestamp.distance(to: proposedPlan.timestamp) < planTimeout,
                           proposedPlan.syncSelectedIncidentLevel <= submitted.syncSelectedIncidentLevel,
                           proposedPlan.syncWorksitesLevel <= submitted.syncWorksitesLevel {
                            syncLogger.log("Skipping redundant sync plan for \(selectedIncidentId)")
                            isRedundant = true
                        }
                    }
                }

                if isRedundant {
                    return false
                } else {
                    submittedSyncPlan = proposedPlan
                    syncLogger.log("Setting sync plan for \(selectedIncidentId)")
                    return true
                }
            }
        }
    }

    private func logStage(
        _ incidentId: Int64,
        _ stage: IncidentCacheStage,
        _ details: String = ""
    ) {
        cacheStageSubject.value = stage

        if appEnv.isProduction {
            return
        }

        let indentation = switch stage {
        case .inactive, .start: ""
        default: "  "
        }
        let stageDetails = "\(stage) \(details)".trim()
        let message = "\(indentation)\(incidentId) \(stageDetails)"
        syncLogger.log(message)

        if appEnv.isDebuggable {
            appLogger.logDebug(message)
        }
    }

    fileprivate func notifyMessage(
        _ statsUpdater: IncidentDataPullStatsUpdater,
        _ messageKey: String,
        _ op: @escaping () async throws -> Void
    ) async throws {
        statsUpdater.setNotificationMessage(translator.t(messageKey))

        try await op()

        try Task.checkCancellation()

        statsUpdater.clearNotificationMessage()
    }

    private func reportStats(
        _ plan: IncidentDataSyncPlan,
        _ stats: IncidentDataPullStats
    ) {
        syncPlanLock.withLock {
            if submittedSyncPlan == plan {
                incidentDataPullStatsSubject.value = stats
            }
        }
    }

    func sync() async throws -> SyncResult {
        var syncPlanTemp = EmptySyncPlan
        var incidentIdTemp = EmptyIncident.id
        syncPlanLock.withLock {
            syncPlanTemp = submittedSyncPlan
            incidentIdTemp = syncPlanTemp.incidentId
            syncingIncidentId.value = incidentIdTemp
            logStage(incidentIdTemp, .start)
        }

        let syncPlan = syncPlanTemp
        let incidentId = incidentIdTemp
        var incidentName = ""

        var partialSyncReasons = [String]()

        do {
            defer {
                reportStats(
                    syncPlan,
                    IncidentDataPullStats(
                        incidentId: incidentId,
                        incidentName: incidentName,
                        isEnded: true
                    )
                )

                syncPlanLock.withLock {
                    if submittedSyncPlan == syncPlan {
                        submittedSyncPlan = EmptySyncPlan
                        cacheStageSubject.value = .end

                        if syncingIncidentId.value == incidentId {
                            syncingIncidentId.value = EmptyIncident.id
                            logStage(incidentId, .end)
                        }
                    }
                }

                syncLogger.flush()
            }

            if syncPlan.syncIncidents {
                logStage(incidentId, .incidents)

                await accountDataRefresher.updateApprovedIncidents(true)
                try await incidentsRepository.pullIncidents(force: true)
            }

            let syncPreferences = try await cachePreferences.eraseToAnyPublisher().asyncFirst()

            let isPaused = syncPreferences.isPaused

            let incidents = await getIncidents()
            if incidents.isEmpty {
                return .error(message: "Failed to sync Incidents")
            }

            incidentName = incidents.first(where: { $0.id == incidentId })?.name ?? ""
            if incidentName.isBlank {
                return .partial(notes: "Incident not found. Waiting for Incident select.")
            }

            let worksitesCoreStatsUpdater = IncidentDataPullStatsUpdater {
                self.reportStats(syncPlan, $0)
            }
            worksitesCoreStatsUpdater.beginPull(incidentId, incidentName, .worksitesCore)

            if syncPlan.syncSelectedIncident {
                logStage(incidentId, .activeIncident)

                try await incidentsRepository.pullIncident(incidentId)
            }

            if syncPlan.restartCache {
                try Task.checkCancellation()

                logStage(incidentId, .worksitesCore, "Restarting Worksites cache")

                try resetIncidentSyncStats(incidentId)
            }

            let syncStatsRecord = try syncParameterDao.getSyncStats(incidentId)
            let regionParameters = syncPreferences.boundedRegionParameters
            let preferencesBoundedRegion = IncidentDataSyncParameters.BoundedRegion(
                latitude: regionParameters.regionLatitude,
                longitude: regionParameters.regionLongitude,
                radius: regionParameters.regionRadiusMiles
            )
            let syncStats = syncStatsRecord ?? IncidentDataSyncParameters(
                incidentId: incidentId,
                syncDataMeasures: IncidentDataSyncParameters.SyncDataMeasure.relative(),
                boundedRegion: preferencesBoundedRegion,
                boundedSyncedAt: Date(timeIntervalSince1970: 0)
            )
            if syncStatsRecord == nil {
                try await syncParameterDao.insertSyncStats(syncStats.asRecord(appLogger))
            }

            try Task.checkCancellation()

            var isSlowDownload = false
            var skipWorksiteCaching = false
            if syncPreferences.isRegionBounded {
                if preferencesBoundedRegion.isDefined {
                    try await notifyMessage(
                        worksitesCoreStatsUpdater,
                        "appCache.syncing_cases_in_designated_area") {
                            try await self.cacheBoundedWorksites(
                                incidentId: incidentId,
                                isPaused: isPaused,
                                isMyLocationBounded: regionParameters.isRegionMyLocation,
                                preferencesBoundedRegion: preferencesBoundedRegion,
                                savedBoundedRegion: syncStats.boundedRegion,
                                syncedAt: syncStats.boundedSyncedAt,
                                statsUpdater: worksitesCoreStatsUpdater,
                            )
                        }
                } else {
                    partialSyncReasons.append("Incomplete bounded region. Skipping Worksites sync.")
                }
            } else {
                if !isPaused {
                    try await preloadBounded(incidentId, worksitesCoreStatsUpdater)
                }

                worksitesCoreStatsUpdater.setDeterminate()

                worksitesCoreStatsUpdater.setStep(current: 1, total: 2)

                // TODO: If not preloaded and times out try caching around coordinates
                let shortResult = try await cacheWorksitesCore(
                    incidentId,
                    isPaused,
                    syncStats,
                    worksitesCoreStatsUpdater,
                )
                isSlowDownload = shortResult.isSlow == true

                if shortResult.isSlow == false,
                   isPaused,
                   !syncStats.syncDataMeasures.core.isDeltaSync
                {
                    _ = try await cacheWorksitesCore(
                        incidentId,
                        false,
                        syncStats,
                        worksitesCoreStatsUpdater,
                    )
                }

                try Task.checkCancellation()
                worksitesCoreStatsUpdater.clearStep()
            }

            try Task.checkCancellation()

            if isPaused,
               isSlowDownload {
                partialSyncReasons.append("Worksite downloads are paused")
                skipWorksiteCaching = true
            }

            if syncPlan.syncSelectedIncident {
                try Task.checkCancellation()

                logStage(incidentId, .activeIncidentOrganization)

                let organizationsStatsUpdater = IncidentDataPullStatsUpdater {
                    self.reportStats(syncPlan, $0)
                }
                organizationsStatsUpdater.beginPull(incidentId, incidentName, .organizations)
                organizationsStatsUpdater.setIndeterminate()

                try await notifyMessage(organizationsStatsUpdater, "appCache.syncing_organizations_in_incident") {
                    await self.incidentsRepository.pullIncidentOrganizations(incidentId)
                }
            }

            if !(skipWorksiteCaching || syncPreferences.isRegionBounded) {
                try Task.checkCancellation()

                logStage(incidentId, .worksitesAdditional)

                let worksitesAdditionalStatsUpdater = IncidentDataPullStatsUpdater {
                    self.reportStats(syncPlan, $0)
                }
                worksitesAdditionalStatsUpdater.beginPull(incidentId, incidentName, .worksitesAdditional)
                worksitesAdditionalStatsUpdater.setStep(current: 2, total: 2)

                let additionalResult = try await cacheAdditionalWorksiteData(
                    incidentId,
                    isPaused,
                    syncStats,
                    worksitesAdditionalStatsUpdater,
                )

                if additionalResult.isSlow == false,
                   isPaused,
                   !syncStats.syncDataMeasures.additional.isDeltaSync
                {
                    _ = try await cacheAdditionalWorksiteData(
                        incidentId,
                        false,
                        syncStats,
                        worksitesAdditionalStatsUpdater,
                    )
                }

                try Task.checkCancellation()
                worksitesAdditionalStatsUpdater.clearStep()
            }
        } catch {
            with(incidentDataPullStatsSubject.value) { stats in
                if stats.queryCount < stats.dataCount {
                    self.speedMonitor.onSpeedChange(isSlow: true)
                }
            }
            throw error
        }

        return if partialSyncReasons.isEmpty {
            .success(notes: "Cached Incident \(incidentId) data.")
        } else {
            .partial(notes: partialSyncReasons.joined(separator: "\n"))
        }
    }

    private func getLocation(_ incidentId: Int64) async -> CLLocationCoordinate2D? {
        if let deviceLocation = await locationProvider.getLocation(timeoutSeconds: 10.0) {
            return deviceLocation.coordinate
        }

        do {
            if let recentsLocation = try await worksitesRepository.getRecentWorksitesCenterLocation(incidentId, limit: 3) {
                let averageLatitude = recentsLocation.latitude
                let averageLongitude = recentsLocation.longitude
                if await locationBounder.isInBounds(
                    incidentId,
                    latitude: averageLatitude,
                    longitude: averageLongitude,
                ) {
                    return CLLocationCoordinate2DMake(averageLatitude, averageLongitude)
                }
            }

            let lastLocation = try await incidentMapTracker.lastLocation.eraseToAnyPublisher().asyncFirst()
            if lastLocation.incidentId == incidentId,
               await locationBounder.isInBounds(
                incidentId,
                latitude: lastLocation.latitude,
                longitude: lastLocation.longitude,
               ) {
                return CLLocationCoordinate2DMake(lastLocation.latitude, lastLocation.longitude)
            }

            if let boundsCenter = await locationBounder.getBoundsCenter(incidentId) {
                if await locationBounder.isInBounds(
                    incidentId,
                    latitude: boundsCenter.coordinate.latitude,
                    longitude: boundsCenter.coordinate.longitude,
                ) {
                    return boundsCenter.coordinate
                }
            }
        } catch {
            appLogger.logError(error)
        }

        return nil
    }

    private func cacheBoundedWorksites(
        incidentId: Int64,
        isPaused: Bool,
        isMyLocationBounded: Bool,
        preferencesBoundedRegion: IncidentDataSyncParameters.BoundedRegion,
        savedBoundedRegion: IncidentDataSyncParameters.BoundedRegion?,
        syncedAt: Date,
        statsUpdater: IncidentDataPullStatsUpdater,
        boundsCacheTimeout: TimeInterval = 1.minutes,
    ) async throws {
        let stage = IncidentCacheStage.worksitesBounded

        func log(_ message: String) {
            logStage(incidentId, stage, message)
        }

        var boundedRegion = preferencesBoundedRegion

        if isMyLocationBounded {
            let locationCoordinates = await getLocation(incidentId)
            if let coordinates = locationCoordinates {
                boundedRegion = boundedRegion.copy {
                    $0.latitude = coordinates.latitude
                    $0.longitude = coordinates.longitude
                }
            }
            if locationCoordinates == nil {
                log(
                    "Current user location is not cached. Falling back to last set location.",
                )
            }
        }

        if !boundedRegion.isDefined {
            log("Bounding region (lat=\(boundedRegion.latitude), lng=\(boundedRegion.longitude), \(boundedRegion.radius) miles) not fully specified")
        } else if syncedAt.distance(to: Date.now) < boundsCacheTimeout,
                  savedBoundedRegion?.isSignificantChange(boundedRegion) == false
        {
            log(
                "Skipping caching of bounded Worksites. Insignificant bounds change between saved \(String(describing: savedBoundedRegion)) and query \(boundedRegion).",
            )
        } else {
            log("Caching bounded Worksites")

            let queryAfter = savedBoundedRegion?.isSignificantChange(boundedRegion) == true ? nil : syncedAt
            let countSpeed = try await cacheBounded(
                incidentId: incidentId,
                isPaused: isPaused,
                boundedRegion: boundedRegion,
                statsUpdater: statsUpdater,
                queryAfter: queryAfter,
                log: log,
            )
            if !isPaused,
               countSpeed.count == 0 {
                // TODO: Alert no Cases were found in the specified region
            }
        }
    }

    private func preloadBounded(
        _ incidentId: Int64,
        _ statsUpdater: IncidentDataPullStatsUpdater,
    ) async throws {
        let localCount = try worksitesRepository.getWorksitesCount(incidentId)
        if localCount > 600 {
            return
        }

        let networkCount = try await networkDataSource.getWorksitesCount(incidentId)
        if networkCount < 3000 {
            return
        }

        if let coordinates = await getLocation(incidentId) {
            let boundedRegion = IncidentDataSyncParameters.BoundedRegion(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                radius: 15.0,
            )
            if boundedRegion.isDefined {
                func log(message: String) {
                    logStage(
                        incidentId,
                        .worksitesPreload,
                        message,
                    )
                }

                do {
                    _ = try await cacheBounded(
                        incidentId: incidentId,
                        isPaused: false,
                        boundedRegion: boundedRegion,
                        statsUpdater: statsUpdater,
                        log: log,
                        maxCount: 300,
                    )
                } catch {
                    appLogger.logError(error)
                }
            }
        }
    }

    // ~60000 Cases longer than 10 mins is reasonably slow
    private let slowDownloadSpeed = 100.0

    private func cacheBounded(
        incidentId: Int64,
        isPaused: Bool,
        boundedRegion: IncidentDataSyncParameters.BoundedRegion,
        statsUpdater: IncidentDataPullStatsUpdater,
        queryAfter: Date? = nil,
        log: (String) -> Void,
        maxCount: Int = 5000,
    ) async throws -> DownloadCountSpeed {
        statsUpdater.setIndeterminate()

        let downloadSpeedTracker = CountTimeTracker()

        let queryCount = if isPaused {
            10
        } else if appEnv.isProduction {
            60
        } else {
            40
        }
        var queryPage = 1
        var savedWorksiteIds: Set<Int64> = Set()
        var initialCount = -1
        var savedCount = 0
        var isOuterRegionReached = false
        let syncStart = Date.now

        var liveRegion = boundedRegion
        var liveQueryAfter = queryAfter

        var isSlowDownload: Bool? = nil

        repeat {
            try Task.checkCancellation()

            let locationDetails = "\(liveRegion.latitude),\(liveRegion.longitude)"

            let networkData = try await downloadSpeedTracker.time {
                let result = try await self.networkDataSource.getWorksitesPage(
                    incidentId: incidentId,
                    pageCount: queryCount,
                    pageOffset: queryPage,
                    latitude: liveRegion.latitude,
                    longitude: liveRegion.longitude,
                    updatedAtAfter: liveQueryAfter,
                )
                if initialCount < 0 {
                    initialCount = result.count ?? 0
                    statsUpdater.setDataCount(initialCount)
                }
                return result.results ?? []
            }

            if networkData.isEmpty {
                isOuterRegionReached = true

                log("Cached (\(savedCount)/\(initialCount)) Worksites around \(locationDetails).")

                if savedCount == 0 {
                    break
                }
            } else {
                if let averageSpeed = downloadSpeedTracker.averageSpeed(){
                    let isSlow = averageSpeed < slowDownloadSpeed
                    isSlowDownload = isSlow
                    self.speedMonitor.onSpeedChange(isSlow: isSlow)
                }

                statsUpdater.addQueryCount(networkData.count)

                queryPage += 1

                let deduplicateWorksites = networkData.filter {
                    !savedWorksiteIds.contains($0.id)
                }
                if deduplicateWorksites.isEmpty {
                    let duplicateCount = networkData.count - deduplicateWorksites.count
                    log("\(duplicateCount) duplicate(s), before")
                    break
                }

                try await saveWorksites(
                    deduplicateWorksites,
                    statsUpdater,
                )
                savedCount += deduplicateWorksites.count

                savedWorksiteIds = Set(networkData.map { $0.id })

                if !savedWorksiteIds.isEmpty {
                    try Task.checkCancellation()

                    do {
                        let networkWorksites =
                        try await networkDataSource.getWorksitesFlagsFormData(savedWorksiteIds)
                        try await saveAdditional(networkWorksites, statsUpdater)
                    } catch {
                        appLogger.logDebug(error)
                    }
                }

                try Task.checkCancellation()

                let maxRadius = liveRegion.radius

                let lastCoordinates = networkData.last!.location.coordinates
                let furthestWorksiteRadius = lastCoordinates.radiusMiles(liveRegion) ?? maxRadius
                isOuterRegionReached = furthestWorksiteRadius >= maxRadius

                let distanceDetails = if isOuterRegionReached {
                    "all within \(furthestWorksiteRadius)/\(maxRadius) mi."
                } else {
                    "up to \(furthestWorksiteRadius) mi."
                }
                log("Cached \(deduplicateWorksites.count) (\(savedCount)/\(initialCount)) \(distanceDetails) around \(locationDetails).")

                if savedCount > maxCount {
                    break
                }

                if let location = await getLocation(incidentId) {
                    let updatedRegion = liveRegion.copy {
                        $0.latitude = location.latitude
                        $0.longitude = location.longitude
                    }
                    if liveRegion.isSignificantChange(updatedRegion) {
                        liveRegion = updatedRegion
                        queryPage = 1
                        liveQueryAfter = nil
                    }
                }
            }

            if isPaused {
                return DownloadCountSpeed(savedCount, isSlowDownload)
            }

            if networkData.isEmpty {
                break
            }
        } while (!isOuterRegionReached)

        if isOuterRegionReached {
            var boundedRegionEncoded = ""
            do {
                boundedRegionEncoded = try JSONEncoder().encodeToString(liveRegion)
            } catch {
                appLogger.logError(error)
            }
            try await syncParameterDao.updateBoundedParameters(
                incidentId,
                boundedRegionEncoded,
                syncStart,
            )
        }

        return DownloadCountSpeed(savedCount, isSlowDownload)
    }

    private func getMaxQueryCount(_ isAdditionalData: Bool) -> Int {
        isAdditionalData ? 4000 : 6500
    }

    private func cacheWorksitesCore(
        _ incidentId: Int64,
        _ isPaused: Bool,
        _ syncParameters: IncidentDataSyncParameters,
        _ statsUpdater: IncidentDataPullStatsUpdater,
    ) async throws -> DownloadCountSpeed {
        var isSlowDownload: Bool? = nil
        var savedCount = 0

        let downloadSpeedTracker = CountTimeTracker()

        let timeMarkers = syncParameters.syncDataMeasures.core
        if !timeMarkers.isDeltaSync {
            let beforeResult = try await cacheWorksitesBefore(
                IncidentCacheStage.worksitesCore,
                incidentId,
                isPaused,
                9000,
                timeMarkers,
                statsUpdater,
                downloadSpeedTracker,
                getTotalCaseCount: nil,
                getNetworkData: { count, before in
                    try await self.networkDataSource.getWorksitesPageBefore(incidentId, count, before)
                },
                saveToDb: { worksites in
                    try await self.saveWorksites(worksites, statsUpdater)
                },
            )

            if isPaused {
                return beforeResult
            }

            isSlowDownload = beforeResult.isSlow
            savedCount = beforeResult.count
        }

        try Task.checkCancellation()

        // TODO: Deltas should account for deleted and/or reclassified

        let afterResult = try await cacheWorksitesAfter(
            IncidentCacheStage.worksitesCore,
            incidentId,
            isPaused,
            9000,
            timeMarkers,
            statsUpdater,
            downloadSpeedTracker,
            getNetworkData: { count, after in
                try await self.networkDataSource.getWorksitesPageAfter(incidentId, count, after)
            },
            saveToDb: { worksites in
                try await self.saveWorksites(worksites, statsUpdater)
            },
        )

        return DownloadCountSpeed(
            savedCount + afterResult.count,
            isSlowDownload == true || afterResult.isSlow == true,
        )
    }

    private func cacheWorksitesBefore<T: WorksiteDataResult, U: WorksiteDataSubset>(
        _ stage: IncidentCacheStage,
        _ incidentId: Int64,
        _ isPaused: Bool,
        _ unmeteredDataCountThreshold: Int,
        _ timeMarkers: IncidentDataSyncParameters.SyncTimeMarker,
        _ statsUpdater: IncidentDataPullStatsUpdater,
        _ downloadSpeedTracker: CountTimeTracker,
        getTotalCaseCount: (() async throws -> Int)?,
        getNetworkData: @escaping (Int, Date) async throws -> T,
        saveToDb: @escaping ([U]) async throws -> Void,
    ) async throws -> DownloadCountSpeed where T.T == U {
        var isSlowDownload: Bool? = nil

        func log(_ message: String) {
            logStage(incidentId, stage, message)
        }

        log("Downloading Worksites before")

        var queryCount = isPaused ? 100 : 1000
        let maxQueryCount = getMaxQueryCount(stage == .worksitesAdditional)
        var beforeTimeMarker = timeMarkers.before
        var savedWorksiteIds: Set<Int64> = Set()
        var initialCount = -1
        var savedCount = 0

        repeat {
            try Task.checkCancellation()

            let networkData = try await downloadSpeedTracker.time {
                // TODO: Edge case where paging data breaks where Cases are equally updated_at
                let result = try await getNetworkData(
                    queryCount,
                    beforeTimeMarker,
                )

                if initialCount < 0 {
                    let totalCount = try await getTotalCaseCount?()
                    let resultCount = result.count ?? 0
                    initialCount = totalCount ?? resultCount
                    statsUpdater.setDataCount(initialCount)
                }
                return result.data ?? []
            }

            if networkData.isEmpty {
                if stage == .worksitesCore {
                    try await syncParameterDao.updateUpdatedBefore(
                        incidentId,
                        IncidentDataSyncParameters.timeMarkerZero,
                    )
                } else {
                    try await syncParameterDao.updateAdditionalUpdatedBefore(
                        incidentId,
                        IncidentDataSyncParameters.timeMarkerZero,
                    )
                }

                log("Cached (\(savedCount)/\(initialCount)) Worksites before.")
            } else {
                if let averageSpeed = downloadSpeedTracker.averageSpeed() {
                    let isSlow = averageSpeed < slowDownloadSpeed
                    isSlowDownload = isSlow
                    speedMonitor.onSpeedChange(isSlow: isSlow)
                }

                statsUpdater.addQueryCount(networkData.count)

                let deduplicateWorksites = networkData.filter {
                    !savedWorksiteIds.contains($0.id)
                }
                if deduplicateWorksites.isEmpty {
                    let duplicateCount = networkData.count - deduplicateWorksites.count
                    log("\(duplicateCount) duplicate(s), before")
                    break
                }

                try await saveToDb(deduplicateWorksites)
                savedCount += deduplicateWorksites.count

                savedWorksiteIds = Set(networkData.map { $0.id })

                queryCount = min(queryCount * 2, maxQueryCount)
                beforeTimeMarker = networkData.last!.updatedAt

                if stage == .worksitesCore {
                    try await syncParameterDao.updateUpdatedBefore(incidentId, beforeTimeMarker)
                } else {
                    try await syncParameterDao.updateAdditionalUpdatedBefore(incidentId, beforeTimeMarker)
                }

                log("Cached \(deduplicateWorksites.count) (\(savedCount)/\(initialCount)) before, back to \(beforeTimeMarker)")
            }

            if isPaused {
                return DownloadCountSpeed(savedCount, isSlowDownload)
            }

            // TODO: Account for low battery
            if initialCount > unmeteredDataCountThreshold,
               !isNetworkUnmetered
            {
                return DownloadCountSpeed(savedCount, isSlowDownload)
            }

            if networkData.isEmpty {
                break
            }
        } while (true)

        return DownloadCountSpeed(savedCount, isSlowDownload)
    }

    private func cacheWorksitesAfter<T: WorksiteDataResult, U: WorksiteDataSubset>(
        _ stage: IncidentCacheStage,
        _ incidentId: Int64,
        _ isPaused: Bool,
        _ unmeteredDataCountThreshold: Int,
        _ timeMarkers: IncidentDataSyncParameters.SyncTimeMarker,
        _ statsUpdater: IncidentDataPullStatsUpdater,
        _ downloadSpeedTracker: CountTimeTracker,
        getNetworkData: @escaping (Int, Date) async throws -> T,
        saveToDb: @escaping ([U]) async throws -> Void,
    ) async throws -> DownloadCountSpeed where T.T == U {
        var isSlowDownload: Bool? = nil

        func log(_ message: String) {
            logStage(incidentId, stage, message)
        }

        var afterTimeMarker = timeMarkers.after

        log("Downloading delta starting at \(afterTimeMarker)")

        var queryCount = isPaused ? 100 : 1000
        let maxQueryCount = getMaxQueryCount(stage == .worksitesAdditional)
        var savedWorksiteIds: Set<Int64> = Set()
        var initialCount = -1
        var savedCount = 0

        repeat {
            try Task.checkCancellation()

            let networkData = try await downloadSpeedTracker.time {
                // TODO: Edge case where paging data breaks where Cases are equally updated_at
                let result = try await getNetworkData(
                    queryCount,
                    afterTimeMarker,
                )
                if initialCount < 0 {
                    initialCount = result.count ?? 0
                    statsUpdater.addDataCount(initialCount)
                }
                return result.data ?? []
            }

            if networkData.isEmpty {
                log("Cached \(savedCount)/\(initialCount) after. No Cases after \(afterTimeMarker)")
            } else {
                if let averageSpeed = downloadSpeedTracker.averageSpeed() {
                    let isSlow = averageSpeed < slowDownloadSpeed
                    isSlowDownload = isSlow
                    speedMonitor.onSpeedChange(isSlow: isSlow)
                }

                statsUpdater.addQueryCount(networkData.count)

                let deduplicateWorksites = networkData.filter {
                    !savedWorksiteIds.contains($0.id)
                }
                if deduplicateWorksites.isEmpty {
                    let duplicateCount = networkData.count - deduplicateWorksites.count
                    log("\(duplicateCount) duplicate(s) after")
                    break
                }

                try await saveToDb(deduplicateWorksites)
                savedCount += deduplicateWorksites.count

                savedWorksiteIds = Set(networkData.map { $0.id })

                queryCount = min(queryCount * 2, maxQueryCount)
                afterTimeMarker = networkData.last!.updatedAt

                if stage == .worksitesCore {
                    try await syncParameterDao.updateUpdatedAfter(incidentId, afterTimeMarker)
                } else {
                    try await syncParameterDao.updateAdditionalUpdatedAfter(incidentId, afterTimeMarker)
                }

                log("Cached \(deduplicateWorksites.count) (\(savedCount)/\(initialCount)) after, up to \(afterTimeMarker)")
            }

            if isPaused {
                return DownloadCountSpeed(savedCount, isSlowDownload)
            }

            // TODO: Account for low battery
            if initialCount > unmeteredDataCountThreshold,
               !isNetworkUnmetered {
                return DownloadCountSpeed(savedCount, isSlowDownload)
            }

            if networkData.isEmpty {
                break
            }
        } while (true)

        return DownloadCountSpeed(savedCount, isSlowDownload)
    }

    private func saveWorksites(
        _ networkWorksites: [NetworkWorksitePage],
        _ statsUpdater: IncidentDataPullStatsUpdater,
    ) async throws {
        let worksites = networkWorksites.map { $0.asRecord() }
        let flags = networkWorksites.map { worksite in
            worksite.flags.filter { flag in flag.invalidatedAt == nil }
                .map { flag in flag.asRecord() }
        }
        let workTypes = networkWorksites.map {
            $0.newestWorkTypes.map { workType in workType.asRecord() }
        }

        var offset = 0
        // TODO: Provide configurable value. Account for device capabilities and/or OS version.
        let dbOperationLimit = 500
        let limit = max(dbOperationLimit, 100)

        while offset < worksites.count {
            let offsetEnd = min((offset + limit), worksites.count)
            let worksiteSubset = Array(ArraySlice(worksites[offset..<offsetEnd]))
            let workTypeSubset = Array(ArraySlice(workTypes[offset..<offsetEnd]))
            try await worksiteDao.syncWorksites(
                worksiteSubset,
                workTypeSubset,
                statsUpdater.startedAt
            )

            let flagSubset = ArraySlice(flags[offset..<offsetEnd])
            try await worksiteDao.syncShortFlags(
                worksiteSubset,
                Array(flagSubset)
            )

            statsUpdater.addSavedCount(worksiteSubset.count)

            offset += limit

            try Task.checkCancellation()
        }
    }

    private func cacheAdditionalWorksiteData(
        _ incidentId: Int64,
        _ isPaused: Bool,
        _ syncParameters: IncidentDataSyncParameters,
        _ statsUpdater: IncidentDataPullStatsUpdater,
    ) async throws -> DownloadCountSpeed {
        var isSlowDownload: Bool? = nil
        var savedCount = 0

        let downloadSpeedTracker = CountTimeTracker()

        let timeMarkers = syncParameters.syncDataMeasures.additional
        if (!timeMarkers.isDeltaSync) {
            let beforeResult = try await cacheWorksitesBefore(
                .worksitesAdditional,
                incidentId,
                isPaused,
                3000,
                timeMarkers,
                statsUpdater,
                downloadSpeedTracker,
                getTotalCaseCount: { try self.worksitesRepository.getWorksitesCount(incidentId) },
                getNetworkData: { count, before in
                    try await self.networkDataSource.getWorksitesFlagsFormDataPageBefore(
                        incidentId,
                        count,
                        before,
                    )
                },
                saveToDb: { worksites in
                    try await self.saveAdditional(worksites, statsUpdater)
                },
            )

            if isPaused {
                return beforeResult
            }

            isSlowDownload = beforeResult.isSlow
            savedCount = beforeResult.count
        }

        try Task.checkCancellation()

        // TODO: Deltas should account for deleted and/or reclassified

        let afterResult = try await cacheWorksitesAfter(
            .worksitesAdditional,
            incidentId,
            isPaused,
            3000,
            timeMarkers,
            statsUpdater,
            downloadSpeedTracker,
            getNetworkData: { count, after in
                try await self.networkDataSource.getWorksitesFlagsFormDataPageAfter(
                    incidentId,
                    count,
                    after,
                )
            },
            saveToDb: { worksites in
                try await self.saveAdditional(worksites, statsUpdater)
            },
        )

        return DownloadCountSpeed(
            savedCount + afterResult.count,
            isSlowDownload == true || afterResult.isSlow == true,
        )
    }

    private func saveAdditional(
        _ networkData: [NetworkFlagsFormData],
        _ statsUpdater: IncidentDataPullStatsUpdater,
    ) async throws {
        let worksiteIds = networkData.map { $0.id }
        let formData = networkData.map {
            $0.formData.map { fd in fd.asWorksiteRecord() }
        }
        let reportedBys = networkData.map { $0.reportedBy }

        var offset = 0
        // TODO: Provide configurable value. Account for device capabilities and/or OS version.
        let dbOperationLimit = 500
        let limit = max(dbOperationLimit, 100)
        var pagedCount = 0
        while offset < worksiteIds.count {
            let offsetEnd = min(offset + limit, worksiteIds.count)
            let worksiteIdsSubset = Array(ArraySlice(worksiteIds[offset..<offsetEnd]))
            let formDataSubset = Array(ArraySlice(formData[offset..<offsetEnd]))
            let reportedBysSubset = Array(ArraySlice(reportedBys[offset..<offsetEnd]))
            // Flags should have been saved by IncidentWorksitesSyncer
            try await worksiteDao.syncAdditionalData(
                worksiteIdsSubset,
                formDataSubset,
                reportedBysSubset
            )

            statsUpdater.addSavedCount(worksiteIdsSubset.count)

            pagedCount += worksiteIdsSubset.count

            offset += limit

            try Task.checkCancellation()
        }
    }

    func resetIncidentSyncStats(_ incidentId: Int64) throws {
        try syncParameterDao.deleteSyncParameters(incidentId)
    }

    func updateCachePreferenes(_ preferences: IncidentWorksitesCachePreferences) {
        incidentCachePreferences.setPreferences(preferences)
    }

    private struct DownloadCountSpeed {
        let count: Int
        let isSlow: Bool?

        init(
            _ count: Int,
            _ isSlow: Bool? = nil
        ) {
            self.count = count
            self.isSlow = isSlow
        }
    }
}

public enum IncidentCacheStage: String, Identifiable, CaseIterable {
    case inactive,
         start,
         incidents,
         worksitesBounded,
         worksitesPreload,
         worksitesCore,
         worksitesAdditional,
         activeIncident,
         activeIncidentOrganization,
         end

    public var id: String { rawValue }
}

private let staticCacheStages = Set([
    IncidentCacheStage.inactive,
    .end,
])

extension IncidentCacheStage {
    var isSyncingStage: Bool {
        !staticCacheStages.contains(self)
    }
}

fileprivate struct IncidentDataSyncPlan: Equatable {
    // May be a new Incident ID
    let incidentId: Int64
    let syncIncidents: Bool
    let syncSelectedIncident: Bool
    let syncActiveIncidentWorksites: Bool
    let syncWorksitesAdditional: Bool
    let restartCache: Bool
    let timestamp: Date

    let syncSelectedIncidentLevel: Int
    let syncWorksitesLevel: Int

    init(
        incidentId: Int64,
        syncIncidents: Bool,
        syncSelectedIncident: Bool,
        syncActiveIncidentWorksites: Bool,
        syncWorksitesAdditional: Bool,
        restartCache: Bool,
        timestamp: Date = Date.now
    ) {
        self.incidentId = incidentId
        self.syncIncidents = syncIncidents
        self.syncSelectedIncident = syncSelectedIncident
        self.syncActiveIncidentWorksites = syncActiveIncidentWorksites
        self.syncWorksitesAdditional = syncWorksitesAdditional
        self.restartCache = restartCache
        self.timestamp = timestamp

        syncSelectedIncidentLevel = {
            if syncSelectedIncident {
                1
            } else {
                0
            }
        }()

        syncWorksitesLevel = {
            if syncWorksitesAdditional {
                2
            } else if syncActiveIncidentWorksites {
                1
            } else {
                0
            }
        }()
    }
}

private let EmptySyncPlan = IncidentDataSyncPlan(
    incidentId: EmptyIncident.id,
    syncIncidents: false,
    syncSelectedIncident: false,
    syncActiveIncidentWorksites: false,
    syncWorksitesAdditional: false,
    restartCache: false,
)

extension Array where Element == Double {
    fileprivate func radiusMiles(_ boundedRegion: IncidentDataSyncParameters.BoundedRegion) -> Double? {
        return count == 2
        ? haversineDistance(
            get(1, 0.0).radians,
            get(0, 0.0).radians,
            boundedRegion.latitude.radians,
            boundedRegion.longitude.radians,
        ).kmToMiles
        : nil
    }
}
