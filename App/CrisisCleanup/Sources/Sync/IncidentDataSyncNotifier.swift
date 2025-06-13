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
        translator: KeyTranslator,
        logger: AppLogger,
    ) {
        self.systemNotifier = systemNotifier
        self.logger = logger

        incidentDataPullReporter.incidentDataPullStats
            .sink { stats in
                if stats.isOngoing,
                self.isSyncing {
                    let title = translator.t("~~Syncing {incident_name}")
                        .replacingOccurrences(of: "{incident_name}", with: stats.incidentName)
                    let text = {
                        var message = stats.notificationMessage
                        if message.isBlank {
                            message = if stats.isIndeterminate {
                                translator.t("~~Saving data...")
                            } else if stats.pullType == .worksitesCore {
                                translator.t("~~Saved {case_count}/{total_case_count} Cases.")
                                    .replacingOccurrences(of: "{case_count}", with: "\(stats.savedCount)")
                                    .replacingOccurrences(of: "{total_case_count}", with: "\(stats.dataCount)")
                            } else if stats.pullType == .worksitesAdditional {
                                translator.t("~~Saved {case_count}/{total_case_count} offline Cases.",)
                                    .replacingOccurrences(of: "{case_count}", with: "\(stats.savedCount)")
                                    .replacingOccurrences(of: "{total_case_count}", with: "\(stats.dataCount)")
                            } else {
                                translator.t("~~Saving more data...")
                            }
                            if 1 <= stats.currentStep,
                               stats.currentStep <= stats.stepTotal {
                                message = translator.t("~~({current_step}/{total_step_count}) {message}")
                                    .replacingOccurrences(of: "{current_step}", with: "\(stats.currentStep)")
                                    .replacingOccurrences(of: "{total_step_count}", with: "\(stats.stepTotal)")
                                    .replacingOccurrences(of: "{message}", with: message)
                            }
                        }
                        return message
                    }()
                    await self.systemNotifier.scheduleNotification(
                        title: title,
                        body: text,
                        identifier: self.syncNotificationId
                    )
                } else if stats.isEnded {
                    self.clearNotifications()
                }
            }
            .store(in: &disposables)
    }

    deinit {
        clearNotifications()
        _ = cancelSubscriptions(disposables)
    }

    private func clearNotifications() {
        systemNotifier.clearNotifications(self.syncNotificationId)
    }

    func notifySync<T>(_ syncOperation: @escaping () async throws -> T) async throws -> T {
        _ = syncCounterLock.withLock {
            syncCounter.getAndIncrement()
        }

        do {
            defer {
                syncCounterLock.withLock {
                    if syncCounter.decrementAndGet() == 0 {
                        clearNotifications()
                    }
                }
            }

            let result = try await syncOperation()
            return result
        }
    }
}
