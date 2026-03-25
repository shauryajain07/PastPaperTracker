import Foundation
import SwiftData

@Model
final class MarkEntry {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var paperName: String
    var examDate: Date
    var scoredMarks: Double
    var totalMarks: Double
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var syncStateRaw: String
    var subject: Subject?
    @Relationship(deleteRule: .cascade, inverse: \MistakeEntry.markEntry) var mistakes: [MistakeEntry]

    init(
        id: UUID = UUID(),
        ownerId: String,
        subject: Subject?,
        paperName: String,
        examDate: Date = .now,
        scoredMarks: Double,
        totalMarks: Double,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncState: SyncState = .pendingUpload
    ) {
        self.id = id
        self.ownerId = ownerId
        self.subject = subject
        self.paperName = paperName
        self.examDate = examDate
        self.scoredMarks = scoredMarks
        self.totalMarks = totalMarks
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
        self.mistakes = []
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpload }
        set { syncStateRaw = newValue.rawValue }
    }

    var percentage: Double {
        guard totalMarks > 0 else { return 0 }
        return (scoredMarks / totalMarks) * 100
    }
}
