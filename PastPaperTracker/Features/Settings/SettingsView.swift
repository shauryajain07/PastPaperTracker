import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var revisionReminderStore: RevisionReminderStore
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

                Section("Revision Reminders") {
                    Toggle(
                        "Enable Reminders",
                        isOn: Binding(
                            get: { revisionReminderStore.isEnabled },
                            set: { enabled in
                                Task {
                                    await revisionReminderStore.setEnabled(enabled)
                                }
                            }
                        )
                    )

                    Picker(
                        "Repeat",
                        selection: Binding(
                            get: { revisionReminderStore.interval },
                            set: { interval in
                                Task {
                                    await revisionReminderStore.setInterval(interval)
                                }
                            }
                        )
                    ) {
                        ForEach(RevisionReminderInterval.allCases) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                    .disabled(!revisionReminderStore.isEnabled)

                    LabeledContent("Permission", value: notificationPermissionLabel)

                    if revisionReminderStore.authorizationStatus == .denied {
                        Button("Open System Settings") {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(settingsURL)
                        }
                    }

                    Text("Past Paper Tracker will send a local revision reminder on the selected 4 to 6 hour cadence.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            .task {
                await revisionReminderStore.refreshAuthorizationStatus()
            }
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

    private var notificationPermissionLabel: String {
        switch revisionReminderStore.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Allowed"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not requested"
        @unknown default:
            return "Unknown"
        }
    }
}
