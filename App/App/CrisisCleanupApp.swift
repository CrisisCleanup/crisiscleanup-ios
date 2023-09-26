import CrisisCleanup
import Firebase
import GooglePlaces
import NeedleFoundation
import SwiftUI

typealias RootComponent = CrisisCleanup.MainComponent

class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var appSettings: AppSettings = AppSettings()
    private(set) var appEnv: AppEnv = AppBuildEnv()

    let externalEventBus = CrisisCleanupExternalEventBus()
    private lazy var activityProcessor: ExternalActivityProcessor = {
        ExternalActivityProcessor(externalEventBus: externalEventBus)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FontBlaster.blast()

        FirebaseApp.configure()
        registerProviderFactories()

        let config = loadConfigProperties()
        appSettings = AppSettings(config)
        appEnv = AppBuildEnv(config)

        GMSPlacesClient.provideAPIKey(appSettings.googleMapsApiKey)

        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }

        return activityProcessor.process(components)
    }
}

@main
struct CrisisCleanupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            let appEnv = appDelegate.appEnv
            let placesSearch = GooglePlaceAddressSearchRepository()
            RootComponent(
                appEnv: appEnv,
                appSettingsProvider: appDelegate.appSettings,
                loggerFactory: AppLoggerProvider(appEnv),
                addressSearchRepository: placesSearch,
                externalEventBus: appDelegate.externalEventBus
            )
            .mainView
        }
    }
}
