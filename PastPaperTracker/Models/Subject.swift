import Foundation
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var syncStateRaw: String
    @Relationship(deleteRule: .cascade, inverse: \MarkEntry.subject) var markEntries: [MarkEntry]
    @Relationship(deleteRule: .cascade, inverse: \MistakeEntry.subject) var mistakeEntries: [MistakeEntry]

    init(
        id: UUID = UUID(),
        ownerId: String,
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncState: SyncState = .pendingUpload
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
        self.markEntries = []
        self.mistakeEntries = []
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpload }
        set { syncStateRaw = newValue.rawValue }
    }
}
