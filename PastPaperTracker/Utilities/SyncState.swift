import Foundation

enum SyncState: String, Codable, CaseIterable, Sendable {
    case synced
    case pendingUpload
    case pendingDelete
    case failed
}
