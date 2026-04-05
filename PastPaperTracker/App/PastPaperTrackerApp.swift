import SwiftUI
import SwiftData

@main
struct PastPaperTrackerApp: App {
    @StateObject private var environment = AppEnvironment()
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRawValue = AppAppearance.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        AppAppearance(rawValue: appAppearanceRawValue)?.preferredColorScheme
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(environment.revisionReminderStore)
                .environmentObject(environment.sessionStore)
                .environmentObject(environment.syncMonitor)
                .modelContainer(environment.modelContainer)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
