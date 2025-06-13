import CrisisCleanup
import Firebase
import GooglePlaces
import NeedleFoundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    lazy var mainComponent: MainComponent = {
        let config = loadConfigProperties()

        let appSettings = AppSettings(config)
        let appEnv = AppBuildEnv(config)

        let loggerFactory: AppLoggerFactory = AppLoggerProvider(appEnv)
        let externalEventBus = CrisisCleanupExternalEventBus()

        let placesSearch = GooglePlaceAddressSearchRepository(loggerFactory: loggerFactory)

        return MainComponent(
            appEnv: appEnv,
            appSettingsProvider: appSettings,
            loggerFactory: loggerFactory,
            addressSearchRepository: placesSearch,
            externalEventBus: externalEventBus
        )
    }()

    private lazy var activityProcessor = ExternalActivityProcessor(externalEventBus: mainComponent.externalEventBus)

    private lazy var externalEventLogger = mainComponent.loggerFactory.getLogger("external-event")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FontBlaster.blast()

        FirebaseApp.configure()

        registerProviderFactories()

        let appSettings = mainComponent.appSettingsProvider

        GMSPlacesClient.provideAPIKey(appSettings.googleMapsApiKey)

        mainComponent.backgroundTaskCoordinator.registerTasks()

        return true
    }

    fileprivate func onExternalLink(_ url: URL) {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        if !activityProcessor.process(components) {
            let path = components.path ?? ""
            let error = GenericError("Unprocessed external event: \(path)")
            externalEventLogger.logError(error)
        }
    }
}

@main
struct CrisisCleanupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            appDelegate.mainComponent
            .mainView
            .onOpenURL { appDelegate.onExternalLink($0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                guard let url = userActivity.webpageURL else {
                    return
                }

                appDelegate.onExternalLink(url)
            }
        }
    }
}
