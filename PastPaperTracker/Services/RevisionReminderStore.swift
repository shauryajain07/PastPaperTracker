import Foundation
import UserNotifications

enum RevisionReminderInterval: Int, CaseIterable, Identifiable {
    case fourHours = 4
    case fiveHours = 5
    case sixHours = 6

    static let defaultValue: RevisionReminderInterval = .fourHours

    var id: Int { rawValue }

    var label: String {
        "Every \(rawValue) hours"
    }

    static func resolve(from rawValue: Int) -> RevisionReminderInterval {
        RevisionReminderInterval(rawValue: rawValue) ?? .defaultValue
    }
}

@MainActor
final class RevisionReminderStore: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool
    @Published var interval: RevisionReminderInterval

    private let defaults: UserDefaults
    private let center: UNUserNotificationCenter
    private let enabledKey = "revision_reminders_enabled"
    private let intervalKey = "revision_reminders_interval_hours"
    private let notificationIdentifier = "revision-reminder"

    init(
        defaults: UserDefaults = .standard,
        center: UNUserNotificationCenter = .current()
    ) {
        self.defaults = defaults
        self.center = center
        if let storedValue = defaults.object(forKey: enabledKey) as? Bool {
            self.isEnabled = storedValue
        } else {
            self.isEnabled = true
        }

        self.interval = RevisionReminderInterval.resolve(
            from: defaults.integer(forKey: intervalKey)
        )
    }

    func bootstrap() async {
        await syncSchedule(promptForPermission: isEnabled)
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    func setEnabled(_ enabled: Bool) async {
        isEnabled = enabled
        defaults.set(enabled, forKey: enabledKey)
        await syncSchedule(promptForPermission: enabled)
    }

    func setInterval(_ interval: RevisionReminderInterval) async {
        self.interval = interval
        defaults.set(interval.rawValue, forKey: intervalKey)
        await syncSchedule()
    }

    private func syncSchedule(promptForPermission: Bool = false) async {
        await refreshAuthorizationStatus()

        guard isEnabled else {
            clearScheduledReminders()
            return
        }

        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await scheduleReminder()
        case .notDetermined:
            if promptForPermission {
                _ = await requestAuthorization()
            } else {
                clearScheduledReminders()
            }
        case .denied:
            clearScheduledReminders()
        @unknown default:
            clearScheduledReminders()
        }
    }

    private func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                await scheduleReminder()
            } else {
                clearScheduledReminders()
            }
            return granted
        } catch {
            await refreshAuthorizationStatus()
            clearScheduledReminders()
            return false
        }
    }

    private func scheduleReminder() async {
        clearScheduledReminders()

        let content = UNMutableNotificationContent()
        content.title = "Revision Check-In"
        content.body = "Open Past Paper Tracker, log a paper, or review a mistake before the next session slips by."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(interval.rawValue * 60 * 60),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            return
        }
    }

    private func clearScheduledReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
    }
}
