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
}

extension BackgroundTaskCoordinator {
    func schedulePushWorksites() {
        schedulePushWorksites(secondsFromNow: 300)
    }

    func schedulePushWorksiteMedia() {
        schedulePushWorksiteMedia(secondsFromNow: 600)
    }
}

class AppBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    private let syncPuller: SyncPuller
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    init(
        syncPuller: SyncPuller,
        syncPusher: SyncPusher,
        loggerFactory: AppLoggerFactory
    ) {
        self.syncPuller = syncPuller
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("sync")
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
            self.handlePushWorksitesMedia(task as! BGAppRefreshTask)
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

    private func handleRefresh(_ task: BGProcessingTask) {
        // TODO: Adjust refresh interval based on remaining Incident data
        scheduleRefresh(secondsFromNow: 4 * 3600)

        let refreshStartTime = Date()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = RefreshIncidentsDataOperation(syncPuller: syncPuller, appLogger: logger)

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "refresh-incidents-data") {
            queue.cancelAllOperations()
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }

            task.setTaskCompleted(success: operation.isSuccessful)
        }

        queue.addOperations([operation], waitUntilFinished: false)
    }

    private func handlePushWorksites(_ task: BGAppRefreshTask) {
        // TODO: Implement
        logger.logDebug("Sync/push worksites data")

    }

    private func handlePushWorksitesMedia(_ task: BGAppRefreshTask) {
        // TODO: Implement
        logger.logDebug("Sync/push worksites media")
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

        switch result {
        case .success:
            isSuccessful = true
        default:
            isSuccessful = false
        }
    }
}
