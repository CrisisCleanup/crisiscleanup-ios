import CrisisCleanup
import Firebase
import GooglePlaces
import NeedleFoundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var appSettings: AppSettings = AppSettings()
    private(set) var appEnv: AppEnv = AppBuildEnv()

    let externalEventBus = CrisisCleanupExternalEventBus()
    private lazy var activityProcessor: ExternalActivityProcessor = ExternalActivityProcessor(externalEventBus: externalEventBus)

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

    fileprivate func onExternalLink(_ url: URL) {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        if !activityProcessor.process(components) {
            print("Unrecognized external URL \(url.absoluteString)")
        }
    }
}

@main
struct CrisisCleanupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            let appEnv = appDelegate.appEnv
            let placesSearch = GooglePlaceAddressSearchRepository()
            MainComponent(
                appEnv: appEnv,
                appSettingsProvider: appDelegate.appSettings,
                loggerFactory: AppLoggerProvider(appEnv),
                addressSearchRepository: placesSearch,
                externalEventBus: appDelegate.externalEventBus
            )
            .mainView
            .onOpenURL { appDelegate.onExternalLink($0) }
        }
    }
}
