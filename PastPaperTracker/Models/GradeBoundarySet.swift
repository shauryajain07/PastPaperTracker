import Foundation
import SwiftData

enum GradeBoundarySetKind: String, Codable, CaseIterable {
    case manualDefault
    case sessionImport

    var sortOrder: Int {
        switch self {
        case .manualDefault:
            return 0
        case .sessionImport:
            return 1
        }
    }
}

struct GradeBoundaryThresholds: Equatable {
    var grade1: Double
    var grade2: Double
    var grade3: Double
    var grade4: Double
    var grade5: Double
    var grade6: Double
    var grade7: Double

    static let zeroed = GradeBoundaryThresholds(
        grade1: 0,
        grade2: 0,
        grade3: 0,
        grade4: 0,
        grade5: 0,
        grade6: 0,
        grade7: 0
    )

    var gradePairsAscending: [(grade: Int, minimumMark: Double)] {
        [
            (1, grade1),
            (2, grade2),
            (3, grade3),
            (4, grade4),
            (5, grade5),
            (6, grade6),
            (7, grade7),
        ]
    }

    var gradePairsDescending: [(grade: Int, minimumMark: Double)] {
        gradePairsAscending.reversed()
    }

    var isStrictlyAscending: Bool {
        let values = gradePairsAscending.map(\.minimumMark)
        return zip(values, values.dropFirst()).allSatisfy { lhs, rhs in lhs <= rhs }
    }
}

@Model
final class GradeBoundarySet {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var title: String
    var kindRaw: String
    var sessionCode: String?
    var sourceImageHash: String?
    var sourceSubjectTitle: String?
    var sourceOCRText: String?
    var boundary1: Double
    var boundary2: Double
    var boundary3: Double
    var boundary4: Double
    var boundary5: Double
    var boundary6: Double
    var boundary7: Double
    var createdAt: Date
    var updatedAt: Date
    var syncStateRaw: String
    var subject: Subject?

    init(
        id: UUID = UUID(),
        ownerId: String,
        subject: Subject?,
        title: String,
        kind: GradeBoundarySetKind,
        sessionCode: String? = nil,
        sourceImageHash: String? = nil,
        sourceSubjectTitle: String? = nil,
        sourceOCRText: String? = nil,
        thresholds: GradeBoundaryThresholds,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncState: SyncState = .pendingUpload
    ) {
        self.id = id
        self.ownerId = ownerId
        self.subject = subject
        self.title = title
        self.kindRaw = kind.rawValue
        self.sessionCode = sessionCode
        self.sourceImageHash = sourceImageHash
        self.sourceSubjectTitle = sourceSubjectTitle
        self.sourceOCRText = sourceOCRText
        self.boundary1 = thresholds.grade1
        self.boundary2 = thresholds.grade2
        self.boundary3 = thresholds.grade3
        self.boundary4 = thresholds.grade4
        self.boundary5 = thresholds.grade5
        self.boundary6 = thresholds.grade6
        self.boundary7 = thresholds.grade7
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
    }

    var kind: GradeBoundarySetKind {
        get { GradeBoundarySetKind(rawValue: kindRaw) ?? .manualDefault }
        set { kindRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpload }
        set { syncStateRaw = newValue.rawValue }
    }

    var thresholds: GradeBoundaryThresholds {
        get {
            GradeBoundaryThresholds(
                grade1: boundary1,
                grade2: boundary2,
                grade3: boundary3,
                grade4: boundary4,
                grade5: boundary5,
                grade6: boundary6,
                grade7: boundary7
            )
        }
        set {
            boundary1 = newValue.grade1
            boundary2 = newValue.grade2
            boundary3 = newValue.grade3
            boundary4 = newValue.grade4
            boundary5 = newValue.grade5
            boundary6 = newValue.grade6
            boundary7 = newValue.grade7
        }
    }

    var normalizedSessionCode: String? {
        sessionCode.flatMap(GradeBoundarySessionCode.canonicalize)
    }

    func minimumMark(for grade: Int) -> Double? {
        switch grade {
        case 1: return boundary1
        case 2: return boundary2
        case 3: return boundary3
        case 4: return boundary4
        case 5: return boundary5
        case 6: return boundary6
        case 7: return boundary7
        default: return nil
        }
    }
}
