import UserNotifications

public protocol SystemNotifier {
    func requestPermission() async -> Bool

    func isAuthorized() async -> Bool

    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        delay: TimeInterval,
    ) async throws

    func clearNotifications(_ notificationId: String)
}

extension SystemNotifier {
    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
    ) async throws {
        try await scheduleNotification(title: title, body: body, identifier: identifier, delay: 0.6)
    }
}

class AppSystemNotifier: NSObject, SystemNotifier, UNUserNotificationCenterDelegate {
    private let logger: AppLogger

    private var notificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("sync")

        super.init()

        notificationCenter.delegate = self
    }

    private let authorizedStatuses = Set([
        UNAuthorizationStatus.authorized,
        .ephemeral,
        .provisional,
    ])

    func isAuthorized() async -> Bool {
        let status = await notificationCenter.notificationSettings().authorizationStatus
        return authorizedStatuses.contains(status)
    }

    func requestPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .provisional])
        } catch {
            logger.logError(error)
        }
        return false
    }

    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        delay: TimeInterval,
    ) async throws {
        guard await isAuthorized() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try Task.checkCancellation()

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.logError(error)
        }
    }

    func clearNotifications(_ notificationId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
    }

    // Show notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.list])
    }
}
