import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if let session = sessionStore.currentSession {
                MainTabView(ownerId: session.id)
            } else {
                AuthView()
            }
        }
        .task {
            await environment.bootstrap()
        }
    }
}
