import CrisisCleanup
import Firebase
import NeedleFoundation
import SwiftUI

typealias RootComponent = CrisisCleanup.MainComponent

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        registerProviderFactories()

        return true
    }
}

@main
struct CrisisCleanupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let config = loadConfigProperties()

    var body: some Scene {
        WindowGroup {
            let appEnv = AppBuildEnv(config)
            RootComponent(
                appEnv: appEnv,
                appSettingsProvider: AppSettings(config),
                loggerFactory: AppLoggerProvider(appEnv)
            )
            .mainView
        }
    }
}
