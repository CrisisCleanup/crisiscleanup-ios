import Combine
import Foundation

class IncidentDataSyncNotifier {
    private let systemNotifier: SystemNotifier
    private let logger: AppLogger

    private let syncCounterLock = NSRecursiveLock()
    private let syncCounter = AtomicInt()
    private var isSyncing: Bool {
        return syncCounterLock.withLock {
            return syncCounter.get() > 0
        }
    }

    private let syncNotificationId = "incident-data-sync"

    private var disposables = Set<AnyCancellable>()

    init(
        systemNotifier: SystemNotifier,
        incidentDataPullReporter: IncidentDataPullReporter,
        logger: AppLogger,
    ) {
        self.systemNotifier = systemNotifier
        self.logger = logger


        incidentDataPullReporter.incidentDataPullStats
            .sink { stats in
                if stats.isOngoing,
                self.isSyncing {
                    // TODO: Update notification
                } else if stats.isEnded {
                    self.systemNotifier.clearNotifications(self.syncNotificationId)
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }
}
