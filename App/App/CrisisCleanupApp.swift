import CrisisCleanup
import Firebase
import GooglePlaces
import NeedleFoundation
import SwiftUI

typealias RootComponent = CrisisCleanup.MainComponent

class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var appSettings: AppSettings = AppSettings()
    private(set) var appEnv: AppEnv = AppBuildEnv()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        registerProviderFactories()

        let config = loadConfigProperties()
        appSettings = AppSettings(config)
        appEnv = AppBuildEnv(config)

        GMSPlacesClient.provideAPIKey(appSettings.googleMapsApiKey)

        return true
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
                addressSearchRepository: placesSearch
            )
            .mainView
        }
    }
}
