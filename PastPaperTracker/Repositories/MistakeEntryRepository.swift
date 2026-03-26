import Foundation
import SwiftData

@MainActor
final class MistakeEntryRepository {
    private let context: ModelContext
    var didSave: (() -> Void)?

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive(ownerId: String) throws -> [MistakeEntry] {
        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchActive(ownerId: String, markEntryID: UUID?) throws -> [MistakeEntry] {
        guard let markEntryID else {
            return try fetchActive(ownerId: ownerId)
        }

        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                $0.syncStateRaw != deleted &&
                $0.markEntry?.id == markEntryID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func mistake(id: UUID) throws -> MistakeEntry? {
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(
        ownerId: String,
        subject: Subject?,
        markEntry: MarkEntry?,
        title: String,
        marksLost: Double?,
        note: String,
        photoPath: String?
    ) throws -> MistakeEntry {
        let mistake = MistakeEntry(
            ownerId: ownerId,
            subject: subject,
            markEntry: markEntry,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            marksLost: marksLost,
            note: note,
            photoPath: photoPath
        )
        context.insert(mistake)
        try save()
        return mistake
    }

    func update(
        _ mistake: MistakeEntry,
        subject: Subject?,
        markEntry: MarkEntry?,
        title: String,
        marksLost: Double?,
        note: String,
        photoPath: String?
    ) throws {
        mistake.subject = subject
        mistake.markEntry = markEntry
        mistake.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        mistake.marksLost = marksLost
        mistake.note = note
        mistake.photoPath = photoPath
        mistake.updatedAt = .now
        if mistake.syncState != .pendingDelete {
            mistake.syncState = .pendingUpload
        }
        try save()
    }

    func markDeleted(_ mistake: MistakeEntry) throws {
        mistake.updatedAt = .now
        mistake.syncState = .pendingDelete
        try save()
    }

    func pendingUploads(ownerId: String) throws -> [MistakeEntry] {
        let pendingUpload = SyncState.pendingUpload.rawValue
        let failed = SyncState.failed.rawValue
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                ($0.syncStateRaw == pendingUpload || $0.syncStateRaw == failed)
            }
        )
        return try context.fetch(descriptor)
    }

    func pendingDeletes(ownerId: String) throws -> [MistakeEntry] {
        let pendingDelete = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw == pendingDelete }
        )
        return try context.fetch(descriptor)
    }

    func markSynced(_ mistake: MistakeEntry, updatedAt: Date) throws {
        mistake.updatedAt = updatedAt
        mistake.syncState = .synced
        try save()
    }

    func purge(_ mistake: MistakeEntry) throws {
        context.delete(mistake)
        try save()
    }

    func upsertRemoteMistakeEntry(
        _ remote: RemoteMistakeEntry,
        subject: Subject?,
        markEntry: MarkEntry?
    ) throws {
        if let existing = try mistake(id: remote.id) {
            guard existing.syncState != .pendingUpload || existing.updatedAt <= remote.updatedAt else { return }
            existing.ownerId = remote.ownerID
            existing.subject = subject
            existing.markEntry = markEntry
            existing.title = remote.title
            existing.marksLost = remote.marksLost
            existing.note = remote.note
            existing.photoPath = remote.photoPath
            existing.createdAt = remote.createdAt
            existing.updatedAt = remote.updatedAt
            existing.syncState = .synced
        } else {
            let mistake = MistakeEntry(
                id: remote.id,
                ownerId: remote.ownerID,
                subject: subject,
                markEntry: markEntry,
                title: remote.title,
                marksLost: remote.marksLost,
                note: remote.note,
                photoPath: remote.photoPath,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt,
                syncState: .synced
            )
            context.insert(mistake)
        }
        try save()
    }

    func migrateOwnership(from oldOwnerID: String, to newOwnerID: String) throws {
        let descriptor = FetchDescriptor<MistakeEntry>(
            predicate: #Predicate { $0.ownerId == oldOwnerID }
        )
        let mistakes = try context.fetch(descriptor)
        for mistake in mistakes {
            mistake.ownerId = newOwnerID
            if mistake.syncState != .pendingDelete {
                mistake.syncState = .pendingUpload
            }
            mistake.updatedAt = .now
        }
        try save()
    }

    private func save() throws {
        try context.save()
        didSave?()
    }
}
