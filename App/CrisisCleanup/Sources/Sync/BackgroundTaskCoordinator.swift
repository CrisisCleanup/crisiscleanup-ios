import BackgroundTasks
import SwiftUI

public protocol BackgroundTaskCoordinator {
    /**
     * Register background tasks
     *
     * Must be called from appropriate point in the app launch sequence.
     */
    func registerTasks()

    func scheduleRefresh(secondsFromNow: Double)
    func schedulePushWorksites(secondsFromNow: Double)
    func schedulePushWorksiteMedia(secondsFromNow: Double)
    func scheduleInactiveCheckup(secondsFromNow: Double)
}

extension BackgroundTaskCoordinator {
    func schedulePushWorksites() {
        schedulePushWorksites(secondsFromNow: 300)
    }

    func schedulePushWorksiteMedia() {
        schedulePushWorksiteMedia(secondsFromNow: 600)
    }

    func scheduleInactiveCheckup() {
        scheduleInactiveCheckup(secondsFromNow: 86400)
    }
}

class AppBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    private let syncPuller: SyncPuller
    private let syncPusher: SyncPusher
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let appSupportRepository: AppSupportRepository
    private let dataManagementRepository: AppDataManagementRepository
    private let appEnv: AppEnv
    private let logger: AppLogger

    private let refreshQueue = OperationQueue()
    private let pushWorksitesQueue = OperationQueue()
    private let pushWorksitesMediaQueue = OperationQueue()
    private let clearInactiveQueue = OperationQueue()

    init(
        syncPuller: SyncPuller,
        syncPusher: SyncPusher,
        worksiteChangeRepository: WorksiteChangeRepository,
        appSupportRepository: AppSupportRepository,
        dataManagementRepository: AppDataManagementRepository,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
    ) {
        self.syncPuller = syncPuller
        self.syncPusher = syncPusher
        self.worksiteChangeRepository = worksiteChangeRepository
        self.appSupportRepository = appSupportRepository
        self.dataManagementRepository = dataManagementRepository
        self.appEnv = appEnv
        logger = loggerFactory.getLogger("sync")

        refreshQueue.maxConcurrentOperationCount = 1
        pushWorksitesQueue.maxConcurrentOperationCount = 1
        pushWorksitesMediaQueue.maxConcurrentOperationCount = 1
        clearInactiveQueue.maxConcurrentOperationCount = 1
    }

    public func registerTasks() {
        let scheduler = BGTaskScheduler.shared

        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.refresh.rawValue, using: nil) { task in
            self.handleRefresh(task as! BGProcessingTask)
        }

        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pushWorksites.rawValue, using: nil) { task in
            self.handlePushWorksites(task as! BGAppRefreshTask)
        }

        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pushWorksiteMedia.rawValue, using: nil) { task in
            self.handlePushWorksitesMedia(task as! BGProcessingTask)
        }

        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.clearInactive.rawValue, using: nil) { task in
            self.handleClearInactive(task as! BGProcessingTask)
        }
    }

    private func scheduleBackgroundTask(
        _ taskType: BackgroundTaskType,
        _ secondsFromNow: Double,
        isProcessingTask: Bool = false,
        requiresNetwork: Bool = true,
    ) {
        let request = {
            let task: BGTaskRequest
            if isProcessingTask {
                let processingTask = BGProcessingTaskRequest(identifier: taskType.rawValue)
                processingTask.requiresNetworkConnectivity = requiresNetwork
                task = processingTask
            } else {
                task = BGAppRefreshTaskRequest(identifier: taskType.rawValue)
            }
            return task
        }()
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(0.0, secondsFromNow))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.logError(error)
        }
    }

    func scheduleRefresh(secondsFromNow: Double) {
        scheduleBackgroundTask(
            BackgroundTaskType.refresh,
            secondsFromNow,
            isProcessingTask: true,
        )
    }

    func schedulePushWorksites(secondsFromNow: Double) {
        scheduleBackgroundTask(
            BackgroundTaskType.pushWorksites,
            secondsFromNow,
        )
    }

    func schedulePushWorksiteMedia(secondsFromNow: Double) {
        scheduleBackgroundTask(
            BackgroundTaskType.pushWorksiteMedia,
            secondsFromNow,
            isProcessingTask: true,
        )
    }

    func scheduleInactiveCheckup(secondsFromNow: Double) {
        scheduleBackgroundTask(
            .clearInactive,
            secondsFromNow,
            isProcessingTask: true
        )
    }

    private func handleRefresh(_ task: BGProcessingTask) {
        // TODO: Adjust refresh interval based on remaining Incident data
        scheduleRefresh(secondsFromNow: 4 * 3600)

        let operation = RefreshIncidentsDataOperation(syncPuller: syncPuller, appLogger: logger)

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "refresh-incidents-data") {
            self.refreshQueue.cancelAllOperations()
        }

        task.expirationHandler = {
            self.refreshQueue.cancelAllOperations()
        }

        operation.completionBlock = {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }

            task.setTaskCompleted(success: operation.isSuccessful)
        }

        refreshQueue.addOperations([operation], waitUntilFinished: false)
    }

    private func handlePushWorksites(_ task: BGAppRefreshTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = UploadWorksitesOperation(
            syncPusher: syncPusher,
            worksiteChangeRepository: worksiteChangeRepository,
            appLogger: logger
        )

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "upload-worksites") {
            self.pushWorksitesQueue.cancelAllOperations()
        }

        task.expirationHandler = {
            self.pushWorksitesQueue.cancelAllOperations()
        }

        operation.completionBlock = {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }

            let nextPushInterval: TimeInterval = (operation.isSuccessful ? 7 : 1.3) * 3600
            self.schedulePushWorksites(secondsFromNow: nextPushInterval)
            if operation.isSuccessful {
                self.schedulePushWorksiteMedia(secondsFromNow: 30)
            }

            task.setTaskCompleted(success: operation.isSuccessful)
        }

        pushWorksitesQueue.addOperations([operation], waitUntilFinished: false)
    }

    private func handlePushWorksitesMedia(_ task: BGProcessingTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = UploadWorksiteMediaOperation(syncPusher: syncPusher, appLogger: logger)

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "upload-media") {
            self.pushWorksitesMediaQueue.cancelAllOperations()
        }

        task.expirationHandler = {
            self.pushWorksitesMediaQueue.cancelAllOperations()
        }

        operation.completionBlock = {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }

            let nextPushInterval: TimeInterval = (operation.isSuccessful ? 13 : 3) * 3600
            self.schedulePushWorksiteMedia(secondsFromNow: nextPushInterval)

            task.setTaskCompleted(success: operation.isSuccessful)
        }

        pushWorksitesMediaQueue.addOperations([operation], waitUntilFinished: false)
    }

    private func handleClearInactive(_ task: BGProcessingTask) {
        let operation = ClearInactiveDataOperation(
            appSupportRepository: appSupportRepository,
            dataManagementRepository: dataManagementRepository,
            appEnv: appEnv,
            appLogger: logger,
        )

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "clear-inactive") {
            self.clearInactiveQueue.cancelAllOperations()
        }

        task.expirationHandler = {
            self.clearInactiveQueue.cancelAllOperations()
        }

        operation.completionBlock = {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }

            let nextCheckInterval: TimeInterval = (operation.isSuccessful ? 2 : 1).days
            self.scheduleInactiveCheckup(secondsFromNow: nextCheckInterval)

            task.setTaskCompleted(success: operation.isSuccessful)
        }

        clearInactiveQueue.addOperations([operation], waitUntilFinished: false)
    }
}

final class RefreshIncidentsDataOperation: AsyncOperation, @unchecked Sendable {
    private let puller: SyncPuller
    private let logger: AppLogger

    private(set) var isSuccessful = false

    init(
        syncPuller: SyncPuller,
        appLogger: AppLogger
    ) {
        puller = syncPuller
        logger = appLogger
    }

    override func operate() async {
        let result = await puller.syncPullIncidentData(
            cancelOngoing: false,
            forcePullIncidents: false,
            cacheSelectedIncident: true,
            cacheActiveIncidentWorksites: true,
            cacheFullWorksites: true,
            restartCacheCheckpoint: false
        )

        // TODO: Refactor and await. Maybe refactor into own operation.
        puller.pullUnauthenticatedData()

        switch result {
        case .success:
            isSuccessful = true
        default:
            isSuccessful = false
        }
    }
}

final class UploadWorksitesOperation: AsyncOperation, @unchecked Sendable {
    private let pusher: SyncPusher
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let logger: AppLogger

    private(set) var isSuccessful = false

    init(
        syncPusher: SyncPusher,
        worksiteChangeRepository: WorksiteChangeRepository,
        appLogger: AppLogger
    ) {
        pusher = syncPusher
        self.worksiteChangeRepository = worksiteChangeRepository
        logger = appLogger
    }

    override func operate() async {
        await pusher.syncWorksites()

        isSuccessful = worksiteChangeRepository.worksiteChangeCount == 0
    }
}

final class UploadWorksiteMediaOperation: AsyncOperation, @unchecked Sendable {
    private let pusher: SyncPusher
    private let logger: AppLogger

    private(set) var isSuccessful = false

    init(
        syncPusher: SyncPusher,
        appLogger: AppLogger
    ) {
        pusher = syncPusher
        logger = appLogger
    }

    override func operate() async {
        isSuccessful = await pusher.syncMedia()
    }
}

final class ClearInactiveDataOperation: AsyncOperation, @unchecked Sendable {
    private let appSupportRepository: AppSupportRepository
    private let dataManagementRepository: AppDataManagementRepository
    private let logger: AppLogger

    private(set) var isSuccessful = false

    private let clearDuration: Double

    init(
        appSupportRepository: AppSupportRepository,
        dataManagementRepository: AppDataManagementRepository,
        appEnv: AppEnv,
        appLogger: AppLogger,
    ) {
        self.appSupportRepository = appSupportRepository
        self.dataManagementRepository = dataManagementRepository
        logger = appLogger

        clearDuration = if appEnv.isProduction {
            60.days
        } else if appEnv.isDebuggable {
            3.days
        } else {
            6.days
        }
    }

    override func operate() async {
        do {
            let metrics = try await appSupportRepository.appMetrics.eraseToAnyPublisher().asyncFirst()
            let latestAppOpen = metrics.openTimestamp
            let delta = latestAppOpen.distance(to: Date.now)

            if clearDuration <= delta,
               delta <= 999.days {
                isSuccessful = await dataManagementRepository.backgroundClearAppData(false)
            } else {
                let daysToClear = (clearDuration - delta) / 86400.0
                logger.logDebug("App will clear in \(daysToClear) days due to inactivity.")
                isSuccessful = true
            }
        } catch {
            logger.logError(error)
            isSuccessful = false
        }
    }
}
