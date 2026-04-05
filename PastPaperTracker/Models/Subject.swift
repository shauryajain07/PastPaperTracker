import Foundation
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var name: String
    var catalogKey: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStateRaw: String
    @Relationship(deleteRule: .cascade, inverse: \MarkEntry.subject) var markEntries: [MarkEntry]
    @Relationship(deleteRule: .cascade, inverse: \MistakeEntry.subject) var mistakeEntries: [MistakeEntry]
    @Relationship(deleteRule: .cascade, inverse: \GradeBoundarySet.subject) var gradeBoundarySets: [GradeBoundarySet]

    init(
        id: UUID = UUID(),
        ownerId: String,
        name: String,
        catalogKey: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncState: SyncState = .pendingUpload
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.catalogKey = catalogKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
        self.markEntries = []
        self.mistakeEntries = []
        self.gradeBoundarySets = []
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpload }
        set { syncStateRaw = newValue.rawValue }
    }

    var activeGradeBoundarySets: [GradeBoundarySet] {
        gradeBoundarySets
            .filter { $0.syncState != .pendingDelete }
            .sorted { lhs, rhs in
                if lhs.kind == rhs.kind {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.kind.sortOrder < rhs.kind.sortOrder
            }
    }

    var manualGradeBoundarySet: GradeBoundarySet? {
        activeGradeBoundarySets.first { $0.kind == .manualDefault }
    }

    var importedGradeBoundarySets: [GradeBoundarySet] {
        activeGradeBoundarySets.filter { $0.kind == .sessionImport }
    }

    var sharedCatalogKey: String {
        let trimmedCatalogKey = catalogKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedCatalogKey.isEmpty {
            return trimmedCatalogKey
        }
        return GradeBoundarySubjectKey.canonicalize(name)
    }
}
