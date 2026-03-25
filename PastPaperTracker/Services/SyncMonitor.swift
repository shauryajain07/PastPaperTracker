import Foundation

@MainActor
final class SyncMonitor: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var lastErrorMessage: String?
}
