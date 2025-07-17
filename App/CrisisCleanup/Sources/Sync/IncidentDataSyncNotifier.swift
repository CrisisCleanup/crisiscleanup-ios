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

        incidentDataPullReporter.incidentDataPullStats.eraseToAnyPublisher()
            .mapLatest { stats in
                if stats.isOngoing,
                self.isSyncing {
                    let title = translator.t("sync.syncing_incident_name")
                        .replacingOccurrences(of: "{incident_name}", with: stats.incidentName)
                    let text = {
                        var message = stats.notificationMessage
                        if message.isBlank {
                            message = if stats.isIndeterminate {
                                translator.t("sync.saving_data")
                            } else if stats.pullType == .worksitesCore {
                                translator.t("sync.saved_case_count_of_total_count")
                                    .replacingOccurrences(of: "{case_count}", with: "\(stats.savedCount)")
                                    .replacingOccurrences(of: "{total_case_count}", with: "\(stats.dataCount)")
                            } else if stats.pullType == .worksitesAdditional {
                                translator.t("sync.saved_case_count_of_total_count_offline",)
                                    .replacingOccurrences(of: "{case_count}", with: "\(stats.savedCount)")
                                    .replacingOccurrences(of: "{total_case_count}", with: "\(stats.dataCount)")
                            } else {
                                translator.t("sync.saving_more_data")
                            }
                            if 1 <= stats.currentStep,
                               stats.currentStep <= stats.stepTotal {
                                message = translator.t("({current_step}/{total_step_count}) {message}")
                                    .replacingOccurrences(of: "{current_step}", with: "\(stats.currentStep)")
                                    .replacingOccurrences(of: "{total_step_count}", with: "\(stats.stepTotal)")
                                    .replacingOccurrences(of: "{message}", with: message)
                            }
                        }
                        return message
                    }()

                    return NotificationAction(title: title, text: text)
                } else if stats.isEnded {
                    return NotificationAction(clear: true)
                }

                return NotificationAction()
            }
            .mapLatest {
                if $0.clear {
                    self.clearNotifications()
                    return true
                } else if $0.title.isNotBlank || $0.text.isNotBlank {
                    try await self.systemNotifier.scheduleNotification(
                        title: $0.title,
                        body: $0.text,
                        identifier: self.syncNotificationId
                    )
                    return true
                }

                return false
            }
            .sink { _ in
                // TODO: mapLatest above doesn't seem to resolve race conditions
                //       Reproduce (or add delay) and resolve
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

private struct NotificationAction {
    let title: String
    let text: String
    let clear: Bool

    init(
        title: String = "",
        text: String = "",
        clear: Bool = false,
    ) {
        self.title = title
        self.text = text
        self.clear = clear
    }
}
