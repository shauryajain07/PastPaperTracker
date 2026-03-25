import Foundation
import SwiftData

@Model
final class MistakeEntry {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var title: String
    var marksLost: Double?
    var note: String
    var photoPath: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStateRaw: String
    var subject: Subject?
    var markEntry: MarkEntry?

    init(
        id: UUID = UUID(),
        ownerId: String,
        subject: Subject?,
        markEntry: MarkEntry? = nil,
        title: String,
        marksLost: Double? = nil,
        note: String,
        photoPath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncState: SyncState = .pendingUpload
    ) {
        self.id = id
        self.ownerId = ownerId
        self.subject = subject
        self.markEntry = markEntry
        self.title = title
        self.marksLost = marksLost
        self.note = note
        self.photoPath = photoPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpload }
        set { syncStateRaw = newValue.rawValue }
    }
}
