import SwiftUI

struct MainTabView: View {
    let ownerId: String

    var body: some View {
        TabView {
            DashboardView(ownerId: ownerId)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.xyaxis.line")
                }

            TestsListView(ownerId: ownerId)
                .tabItem {
                    Label("Tests", systemImage: "doc.text.magnifyingglass")
                }

            MistakesListView(ownerId: ownerId)
                .tabItem {
                    Label("Mistakes", systemImage: "exclamationmark.bubble")
                }
        }
        .tint(StudyTheme.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
