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
        isProcessingTask: Bool = false
    ) {
        let request = isProcessingTask
        ? BGProcessingTaskRequest(identifier: taskType.rawValue)
        : BGAppRefreshTaskRequest(identifier: taskType.rawValue)
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
            isProcessingTask: true
        )
    }

    func schedulePushWorksites(secondsFromNow: Double) {
        scheduleBackgroundTask(BackgroundTaskType.pushWorksites, secondsFromNow)
    }

    func schedulePushWorksiteMedia(secondsFromNow: Double) {
        scheduleBackgroundTask(BackgroundTaskType.pushWorksiteMedia, secondsFromNow)
    }

    private func handleRefresh(_ task: BGProcessingTask) {
        scheduleRefresh(secondsFromNow: 4 * 60 * 60)

        let refreshStartTime = Date()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = RefreshIncidentsDataOperation(syncPuller: syncPuller, appLogger: logger)

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            let extensionTimeEnd = Date()
            self.logger.logDebug("Refresh background time over. Started \(refreshStartTime). Ended \(extensionTimeEnd).")

            queue.cancelAllOperations()
        }

        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            let refreshCompleteTime = Date()
            self.logger.logDebug("Refresh task is completing. Started \(refreshStartTime). Completed \(refreshCompleteTime).")

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

class RefreshIncidentsDataOperation: Operation {
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

    override func main() {
        do {
            // TODO: Implement
            logger.logDebug("Pending refresh incidents data")

            isSuccessful = true
        } catch {
            logger.logError(error)
        }
    }
}
