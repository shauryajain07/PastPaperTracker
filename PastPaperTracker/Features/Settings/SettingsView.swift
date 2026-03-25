import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var syncMonitor: SyncMonitor

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Mode", value: sessionStore.currentSession?.isGuest == true ? "Offline" : "Email")
                    LabeledContent("User", value: sessionStore.currentSession?.email ?? sessionStore.currentSession?.id ?? "Signed out")
                }

                Section("Sync") {
                    LabeledContent("Backend", value: environment.authService.isConfigured ? "Supabase" : "Not configured")
                    LabeledContent("State", value: syncMonitor.isSyncing ? "Syncing" : "Idle")
                    LabeledContent("Last Sync", value: syncMonitor.lastSyncDate.map { Formatters.shortDate.string(from: $0) } ?? "Never")

                    Button("Sync Now") {
                        Task {
                            await environment.triggerSync()
                        }
                    }
                    .disabled(syncMonitor.isSyncing)
                }

                if let error = syncMonitor.lastErrorMessage {
                    Section("Last Error") {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                if !environment.authService.isConfigured {
                    Section("Configuration") {
                        Text("Copy `SupabaseConfig.plist.example` to `SupabaseConfig.plist` in the app resources and add your project URL, anon key, and storage bucket.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await environment.signOut()
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .studyScreenBackground()
    }
}
