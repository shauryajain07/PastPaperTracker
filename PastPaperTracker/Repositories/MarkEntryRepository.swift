import Foundation
import SwiftData

@MainActor
final class MarkEntryRepository {
    private let context: ModelContext
    var didSave: (() -> Void)?

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive(ownerId: String) throws -> [MarkEntry] {
        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sortBy: [SortDescriptor(\.examDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchActive(ownerId: String, subjectID: UUID?) throws -> [MarkEntry] {
        guard let subjectID else {
            return try fetchActive(ownerId: ownerId)
        }

        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                $0.syncStateRaw != deleted &&
                $0.subject?.id == subjectID
            },
            sortBy: [SortDescriptor(\.examDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func markEntry(id: UUID) throws -> MarkEntry? {
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(
        ownerId: String,
        subject: Subject?,
        paperName: String,
        examDate: Date,
        scoredMarks: Double,
        totalMarks: Double,
        notes: String
    ) throws -> MarkEntry {
        let entry = MarkEntry(
            ownerId: ownerId,
            subject: subject,
            paperName: paperName.trimmingCharacters(in: .whitespacesAndNewlines),
            examDate: examDate,
            scoredMarks: scoredMarks,
            totalMarks: totalMarks,
            notes: notes
        )
        context.insert(entry)
        try save()
        return entry
    }

    func update(
        _ entry: MarkEntry,
        subject: Subject?,
        paperName: String,
        examDate: Date,
        scoredMarks: Double,
        totalMarks: Double,
        notes: String
    ) throws {
        entry.subject = subject
        entry.paperName = paperName.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.examDate = examDate
        entry.scoredMarks = scoredMarks
        entry.totalMarks = totalMarks
        entry.notes = notes
        entry.updatedAt = .now
        if entry.syncState != .pendingDelete {
            entry.syncState = .pendingUpload
        }
        try save()
    }

    func markDeleted(_ entry: MarkEntry) throws {
        entry.updatedAt = .now
        entry.syncState = .pendingDelete
        try save()
    }

    func pendingUploads(ownerId: String) throws -> [MarkEntry] {
        let pendingUpload = SyncState.pendingUpload.rawValue
        let failed = SyncState.failed.rawValue
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                ($0.syncStateRaw == pendingUpload || $0.syncStateRaw == failed)
            }
        )
        return try context.fetch(descriptor)
    }

    func pendingDeletes(ownerId: String) throws -> [MarkEntry] {
        let pendingDelete = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw == pendingDelete }
        )
        return try context.fetch(descriptor)
    }

    func markSynced(_ entry: MarkEntry, updatedAt: Date) throws {
        entry.updatedAt = updatedAt
        entry.syncState = .synced
        try save()
    }

    func purge(_ entry: MarkEntry) throws {
        context.delete(entry)
        try save()
    }

    func upsertRemoteMarkEntry(_ remote: RemoteMarkEntry, subject: Subject?) throws {
        if let existing = try markEntry(id: remote.id) {
            guard existing.syncState != .pendingUpload || existing.updatedAt <= remote.updatedAt else { return }
            existing.ownerId = remote.ownerID
            existing.subject = subject
            existing.paperName = remote.paperName
            existing.examDate = remote.examDate
            existing.scoredMarks = remote.scoredMarks
            existing.totalMarks = remote.totalMarks
            existing.notes = remote.notes
            existing.createdAt = remote.createdAt
            existing.updatedAt = remote.updatedAt
            existing.syncState = .synced
        } else {
            let entry = MarkEntry(
                id: remote.id,
                ownerId: remote.ownerID,
                subject: subject,
                paperName: remote.paperName,
                examDate: remote.examDate,
                scoredMarks: remote.scoredMarks,
                totalMarks: remote.totalMarks,
                notes: remote.notes,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt,
                syncState: .synced
            )
            context.insert(entry)
        }
        try save()
    }

    func migrateOwnership(from oldOwnerID: String, to newOwnerID: String) throws {
        let descriptor = FetchDescriptor<MarkEntry>(
            predicate: #Predicate { $0.ownerId == oldOwnerID }
        )
        let entries = try context.fetch(descriptor)
        for entry in entries {
            entry.ownerId = newOwnerID
            if entry.syncState != .pendingDelete {
                entry.syncState = .pendingUpload
            }
            entry.updatedAt = .now
        }
        try save()
    }

    private func save() throws {
        try context.save()
        didSave?()
    }
}
