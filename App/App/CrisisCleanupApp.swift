import SwiftUI
import CrisisCleanup

@main
struct CrisisCleanupApp: App {
    @StateObject private var model = MainViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
