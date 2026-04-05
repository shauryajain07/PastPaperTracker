import Foundation
import SwiftData

struct ImportedGradeBoundaryRow: Equatable {
    let title: String
    let sessionCode: String
    let thresholds: GradeBoundaryThresholds
}

@MainActor
final class GradeBoundaryRepository {
    private let context: ModelContext
    var didSave: (() -> Void)?

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive(ownerId: String, subjectID: UUID? = nil) throws -> [GradeBoundarySet] {
        let deleted = SyncState.pendingDelete.rawValue

        if let subjectID {
            let descriptor = FetchDescriptor<GradeBoundarySet>(
                predicate: #Predicate {
                    $0.ownerId == ownerId &&
                    $0.syncStateRaw != deleted &&
                    $0.subject?.id == subjectID
                },
                sortBy: [
                    SortDescriptor(\.kindRaw),
                    SortDescriptor(\.title),
                ]
            )
            return try context.fetch(descriptor)
        }

        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sortBy: [
                SortDescriptor(\.kindRaw),
                SortDescriptor(\.title),
            ]
        )
        return try context.fetch(descriptor)
    }

    func gradeBoundary(id: UUID) throws -> GradeBoundarySet? {
        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func manualBoundary(for subject: Subject) -> GradeBoundarySet? {
        subject.manualGradeBoundarySet
    }

    @discardableResult
    func upsertManualBoundary(
        ownerId: String,
        subject: Subject,
        thresholds: GradeBoundaryThresholds
    ) throws -> GradeBoundarySet {
        if let existing = manualBoundary(for: subject) {
            existing.title = "Default"
            existing.thresholds = thresholds
            existing.updatedAt = .now
            existing.kind = .manualDefault
            existing.sessionCode = nil
            existing.sourceImageHash = nil
            existing.sourceSubjectTitle = nil
            existing.sourceOCRText = nil
            if existing.syncState != .pendingDelete {
                existing.syncState = .pendingUpload
            }
            try save()
            return existing
        }

        let boundary = GradeBoundarySet(
            ownerId: ownerId,
            subject: subject,
            title: "Default",
            kind: .manualDefault,
            thresholds: thresholds
        )
        context.insert(boundary)
        try save()
        return boundary
    }

    func existingImport(ownerId: String, subjectID: UUID, imageHash: String) throws -> [GradeBoundarySet] {
        let deleted = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                $0.subject?.id == subjectID &&
                $0.syncStateRaw != deleted &&
                $0.sourceImageHash == imageHash
            },
            sortBy: [SortDescriptor(\.title)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func upsertImportedBoundaries(
        ownerId: String,
        subject: Subject,
        imageHash: String,
        sourceSubjectTitle: String?,
        sourceOCRText: String,
        rows: [ImportedGradeBoundaryRow]
    ) throws -> [GradeBoundarySet] {
        let existingForImage = try existingImport(ownerId: ownerId, subjectID: subject.id, imageHash: imageHash)
        if !existingForImage.isEmpty {
            return existingForImage
        }

        var existingBySession = importedSetsBySession(for: subject)

        var saved: [GradeBoundarySet] = []
        for row in rows {
            let set = upsertImportedBoundary(
                ownerId: ownerId,
                subject: subject,
                title: row.title,
                sessionCode: row.sessionCode,
                sourceImageHash: imageHash,
                sourceSubjectTitle: sourceSubjectTitle,
                sourceOCRText: sourceOCRText,
                thresholds: row.thresholds,
                existingBySession: &existingBySession
            )
            saved.append(set)
        }

        try save()
        return saved.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    @discardableResult
    func upsertSharedSelection(
        ownerId: String,
        subject: Subject,
        sharedSet: SharedGradeBoundaryCatalogEntry
    ) throws -> GradeBoundarySet {
        var existingBySession = importedSetsBySession(for: subject)
        let set = upsertImportedBoundary(
            ownerId: ownerId,
            subject: subject,
            title: sharedSet.title,
            sessionCode: sharedSet.sessionCode,
            sourceImageHash: sharedSet.sourceImageHash,
            sourceSubjectTitle: sharedSet.sourceSubjectTitle ?? sharedSet.subjectTitle,
            sourceOCRText: "",
            thresholds: sharedSet.thresholds,
            existingBySession: &existingBySession
        )
        try save()
        return set
    }

    func markDeleted(_ set: GradeBoundarySet) throws {
        set.updatedAt = .now
        set.syncState = .pendingDelete
        try save()
    }

    func pendingUploads(ownerId: String) throws -> [GradeBoundarySet] {
        let pendingUpload = SyncState.pendingUpload.rawValue
        let failed = SyncState.failed.rawValue
        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate {
                $0.ownerId == ownerId &&
                ($0.syncStateRaw == pendingUpload || $0.syncStateRaw == failed)
            }
        )
        return try context.fetch(descriptor)
    }

    func pendingDeletes(ownerId: String) throws -> [GradeBoundarySet] {
        let pendingDelete = SyncState.pendingDelete.rawValue
        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate { $0.ownerId == ownerId && $0.syncStateRaw == pendingDelete }
        )
        return try context.fetch(descriptor)
    }

    func markSynced(_ set: GradeBoundarySet, updatedAt: Date) throws {
        set.updatedAt = updatedAt
        set.syncState = .synced
        try save()
    }

    func purge(_ set: GradeBoundarySet) throws {
        context.delete(set)
        try save()
    }

    func upsertRemoteGradeBoundarySet(_ remote: RemoteGradeBoundarySet, subject: Subject?) throws {
        if let existing = try gradeBoundary(id: remote.id) {
            guard existing.syncState != .pendingUpload || existing.updatedAt <= remote.updatedAt else { return }
            existing.ownerId = remote.ownerID
            existing.subject = subject
            existing.title = remote.title
            existing.kindRaw = remote.kind
            existing.sessionCode = remote.sessionCode
            existing.sourceImageHash = remote.sourceImageHash
            existing.sourceSubjectTitle = remote.sourceSubjectTitle
            existing.sourceOCRText = remote.sourceOCRText
            existing.thresholds = remote.thresholds
            existing.createdAt = remote.createdAt
            existing.updatedAt = remote.updatedAt
            existing.syncState = .synced
        } else {
            let boundary = GradeBoundarySet(
                id: remote.id,
                ownerId: remote.ownerID,
                subject: subject,
                title: remote.title,
                kind: GradeBoundarySetKind(rawValue: remote.kind) ?? .manualDefault,
                sessionCode: remote.sessionCode,
                sourceImageHash: remote.sourceImageHash,
                sourceSubjectTitle: remote.sourceSubjectTitle,
                sourceOCRText: remote.sourceOCRText,
                thresholds: remote.thresholds,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt,
                syncState: .synced
            )
            context.insert(boundary)
        }
        try save()
    }

    func migrateOwnership(from oldOwnerID: String, to newOwnerID: String) throws {
        let descriptor = FetchDescriptor<GradeBoundarySet>(
            predicate: #Predicate { $0.ownerId == oldOwnerID }
        )
        let boundaries = try context.fetch(descriptor)
        for boundary in boundaries {
            boundary.ownerId = newOwnerID
            if boundary.syncState != .pendingDelete {
                boundary.syncState = .pendingUpload
            }
            boundary.updatedAt = .now
        }
        try save()
    }

    private func importedSetsBySession(for subject: Subject) -> [String: GradeBoundarySet] {
        Dictionary(
            uniqueKeysWithValues: subject.importedGradeBoundarySets.compactMap { set -> (String, GradeBoundarySet)? in
                guard let code = set.normalizedSessionCode else { return nil }
                return (code, set)
            }
        )
    }

    @discardableResult
    private func upsertImportedBoundary(
        ownerId: String,
        subject: Subject,
        title: String,
        sessionCode: String,
        sourceImageHash: String?,
        sourceSubjectTitle: String?,
        sourceOCRText: String,
        thresholds: GradeBoundaryThresholds,
        existingBySession: inout [String: GradeBoundarySet]
    ) -> GradeBoundarySet {
        let canonicalCode = GradeBoundarySessionCode.canonicalize(sessionCode) ?? sessionCode

        if let existing = existingBySession[canonicalCode] {
            existing.title = title
            existing.kind = .sessionImport
            existing.sessionCode = canonicalCode
            existing.sourceImageHash = sourceImageHash
            existing.sourceSubjectTitle = sourceSubjectTitle
            existing.sourceOCRText = sourceOCRText
            existing.thresholds = thresholds
            existing.updatedAt = .now
            if existing.syncState != .pendingDelete {
                existing.syncState = .pendingUpload
            }
            return existing
        }

        let newSet = GradeBoundarySet(
            ownerId: ownerId,
            subject: subject,
            title: title,
            kind: .sessionImport,
            sessionCode: canonicalCode,
            sourceImageHash: sourceImageHash,
            sourceSubjectTitle: sourceSubjectTitle,
            sourceOCRText: sourceOCRText,
            thresholds: thresholds
        )
        context.insert(newSet)
        existingBySession[canonicalCode] = newSet
        return newSet
    }

    private func save() throws {
        try context.save()
        didSave?()
    }
}
