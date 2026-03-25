import SwiftUI
import SwiftData

@main
struct PastPaperTrackerApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(environment.sessionStore)
                .environmentObject(environment.syncMonitor)
                .modelContainer(environment.modelContainer)
        }
    }
}
