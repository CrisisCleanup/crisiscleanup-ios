import CrisisCleanup
import NeedleFoundation
import SwiftUI

typealias RootComponent = CrisisCleanup.MainComponent

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        registerProviderFactories()

        return true
    }
}

@main
struct CrisisCleanupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootComponent().mainView
        }
    }
}
