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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    StudyPageHeader(
                        eyebrow: "SETTINGS",
                        title: "Preferences & sync",
                        detail: "Manage account mode, revision reminders, and how this device connects to your study data."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Account",
                            detail: "Keep your sign-in mode and active profile visible at a glance."
                        )

                        VStack(spacing: 16) {
                            StudyInfoRow(
                                title: "Mode",
                                value: sessionStore.currentSession?.isGuest == true ? "Offline" : "Email"
                            )

                            Divider()

                            StudyInfoRow(
                                title: "User",
                                value: sessionStore.currentSession?.email ?? sessionStore.currentSession?.id ?? "Signed out"
                            )
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Sync",
                            detail: "Check whether the app is connected and trigger a manual sync when needed."
                        )

                        VStack(spacing: 16) {
                            StudyInfoRow(
                                title: "Backend",
                                value: environment.authService.isConfigured ? "Supabase" : "Not configured"
                            )

                            Divider()

                            StudyInfoRow(
                                title: "State",
                                value: syncMonitor.isSyncing ? "Syncing" : "Idle"
                            )

                            Divider()

                            StudyInfoRow(
                                title: "Last Sync",
                                value: syncMonitor.lastSyncDate.map { Formatters.shortDate.string(from: $0) } ?? "Never"
                            )

                            Button("Sync Now") {
                                Task {
                                    await environment.triggerSync()
                                }
                            }
                            .buttonStyle(StudyPrimaryButtonStyle())
                            .disabled(syncMonitor.isSyncing)
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Revision Reminders",
                            detail: "Choose whether the app nudges you back into review during the day."
                        )

                        VStack(alignment: .leading, spacing: 18) {
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
                            .tint(StudyTheme.accent)

                            Divider()

                            StudyFieldBlock(
                                title: "Repeat",
                                detail: "The reminder repeats every 4 to 6 hours while enabled."
                            ) {
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
                                        Text(shortLabel(for: interval)).tag(interval)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .disabled(!revisionReminderStore.isEnabled)
                            }

                            Divider()

                            StudyInfoRow(title: "Permission", value: notificationPermissionLabel)

                            if revisionReminderStore.authorizationStatus == .denied {
                                Button("Open System Settings") {
                                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                                    openURL(settingsURL)
                                }
                                .buttonStyle(StudySecondaryButtonStyle())
                            }

                            Text("Past Paper Tracker sends a local reminder on the cadence you choose here.")
                                .font(.footnote)
                                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                        }
                        .studyPanel(padding: 20)
                    }

                    if let error = syncMonitor.lastErrorMessage {
                        Text(error)
                            .foregroundStyle(StudyTheme.rose)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(StudyTheme.rose.opacity(0.10))
                            }
                    }

                    if !environment.authService.isConfigured {
                        VStack(alignment: .leading, spacing: 14) {
                            StudySectionHeader(
                                title: "Configuration",
                                detail: "Cloud sync is currently disabled on this device."
                            )

                            Text("Copy `SupabaseConfig.plist.example` to `SupabaseConfig.plist` in the app resources and add your project URL, anon key, and storage bucket.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .studyPanel(padding: 20)
                        }
                    }

                    Button(role: .destructive) {
                        Task {
                            await environment.signOut()
                            dismiss()
                        }
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(StudyTheme.rose)
                    }
                    .buttonStyle(StudySecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
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
    }

    private func shortLabel(for interval: RevisionReminderInterval) -> String {
        "\(interval.rawValue)h"
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
