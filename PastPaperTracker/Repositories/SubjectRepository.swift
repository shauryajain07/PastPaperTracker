import Foundation
import SwiftData

@MainActor
final class SubjectRepository {
    private let context: ModelContext
    var didSave: (() -> Void)?

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive(ownerId: String) throws -> [Subject] {
        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func subject(id: UUID) throws -> Subject? {
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(ownerId: String, name: String) throws -> Subject {
        let subject = Subject(ownerId: ownerId, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(subject)
        try save()
        return subject
    }

    func update(_ subject: Subject, name: String) throws {
        subject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        subject.updatedAt = .now
        if subject.syncState != .pendingDelete {
            subject.syncState = .pendingUpload
        }
        try save()
    }

    func markDeleted(_ subject: Subject) throws {
        subject.updatedAt = .now
        subject.syncState = .pendingDelete
        try save()
    }

    func pendingUploads(ownerId: String) throws -> [Subject] {
        let pendingUpload = SyncState.pendingUpload.rawValue
        let failed = SyncState.failed.rawValue
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.ownerId == ownerId && ($0.syncStateRaw == pendingUpload || $0.syncStateRaw == failed) }
        )
        return try context.fetch(descriptor)
    }

    func pendingDeletes(ownerId: String) throws -> [Subject] {
        let pendingDelete = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw == pendingDelete }
        )
        return try context.fetch(descriptor)
    }

    func markSynced(_ subject: Subject, updatedAt: Date) throws {
        subject.updatedAt = updatedAt
        subject.syncState = .synced
        try save()
    }

    func purge(_ subject: Subject) throws {
        context.delete(subject)
        try save()
    }

    func upsertRemoteSubject(_ remote: RemoteSubject) throws {
        if let existing = try subject(id: remote.id) {
            guard existing.syncState != .pendingUpload || existing.updatedAt <= remote.updatedAt else { return }
            existing.ownerId = remote.ownerID
            existing.name = remote.name
            existing.createdAt = remote.createdAt
            existing.updatedAt = remote.updatedAt
            existing.syncState = .synced
        } else {
            let subject = Subject(
                id: remote.id,
                ownerId: remote.ownerID,
                name: remote.name,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt,
                syncState: .synced
            )
            context.insert(subject)
        }
        try save()
    }

    func migrateOwnership(from oldOwnerID: String, to newOwnerID: String) throws {
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.ownerId == oldOwnerID }
        )
        let subjects = try context.fetch(descriptor)
        for subject in subjects {
            subject.ownerId = newOwnerID
            if subject.syncState != .pendingDelete {
                subject.syncState = .pendingUpload
            }
            subject.updatedAt = .now
        }
        try save()
    }

    private func save() throws {
        try context.save()
        didSave?()
    }
}
