import Foundation

struct RemoteSubject: Codable {
    let id: UUID
    let ownerID: String
    let name: String
    let catalogKey: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case catalogKey = "catalog_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, ownerID: String, name: String, catalogKey: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.catalogKey = catalogKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(subject: Subject) {
        self.init(
            id: subject.id,
            ownerID: subject.ownerId,
            name: subject.name,
            catalogKey: subject.sharedCatalogKey,
            createdAt: subject.createdAt,
            updatedAt: subject.updatedAt
        )
    }
}

struct SharedSubjectCatalogEntry: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var subjectKey: String { id }

    init(id: String, title: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(subject: Subject) {
        let subjectKey = subject.sharedCatalogKey
        guard !subjectKey.isEmpty else { return nil }
        self.init(
            id: subjectKey,
            title: subject.name,
            createdAt: subject.createdAt,
            updatedAt: subject.updatedAt
        )
    }
}

struct RemoteGradeBoundarySet: Codable {
    let id: UUID
    let ownerID: String
    let subjectID: UUID?
    let title: String
    let kind: String
    let sessionCode: String?
    let sourceImageHash: String?
    let sourceSubjectTitle: String?
    let sourceOCRText: String?
    let boundary1: Double
    let boundary2: Double
    let boundary3: Double
    let boundary4: Double
    let boundary5: Double
    let boundary6: Double
    let boundary7: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case subjectID = "subject_id"
        case title
        case kind
        case sessionCode = "session_code"
        case sourceImageHash = "source_image_hash"
        case sourceSubjectTitle = "source_subject_title"
        case sourceOCRText = "source_ocr_text"
        case boundary1 = "boundary_1"
        case boundary2 = "boundary_2"
        case boundary3 = "boundary_3"
        case boundary4 = "boundary_4"
        case boundary5 = "boundary_5"
        case boundary6 = "boundary_6"
        case boundary7 = "boundary_7"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var thresholds: GradeBoundaryThresholds {
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

    init(entry: GradeBoundarySet) {
        self.id = entry.id
        self.ownerID = entry.ownerId
        self.subjectID = entry.subject?.id
        self.title = entry.title
        self.kind = entry.kind.rawValue
        self.sessionCode = entry.sessionCode
        self.sourceImageHash = entry.sourceImageHash
        self.sourceSubjectTitle = entry.sourceSubjectTitle
        self.sourceOCRText = entry.sourceOCRText
        self.boundary1 = entry.boundary1
        self.boundary2 = entry.boundary2
        self.boundary3 = entry.boundary3
        self.boundary4 = entry.boundary4
        self.boundary5 = entry.boundary5
        self.boundary6 = entry.boundary6
        self.boundary7 = entry.boundary7
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
    }
}

struct SharedGradeBoundaryCatalogEntry: Codable, Identifiable, Equatable {
    let id: String
    let contributorID: String?
    let subjectKey: String
    let subjectTitle: String
    let title: String
    let sessionCode: String
    let sourceImageHash: String?
    let sourceSubjectTitle: String?
    let boundary1: Double
    let boundary2: Double
    let boundary3: Double
    let boundary4: Double
    let boundary5: Double
    let boundary6: Double
    let boundary7: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contributorID = "contributor_id"
        case subjectKey = "subject_key"
        case subjectTitle = "subject_title"
        case title
        case sessionCode = "session_code"
        case sourceImageHash = "source_image_hash"
        case sourceSubjectTitle = "source_subject_title"
        case boundary1 = "boundary_1"
        case boundary2 = "boundary_2"
        case boundary3 = "boundary_3"
        case boundary4 = "boundary_4"
        case boundary5 = "boundary_5"
        case boundary6 = "boundary_6"
        case boundary7 = "boundary_7"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var thresholds: GradeBoundaryThresholds {
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

    var normalizedSessionCode: String {
        GradeBoundarySessionCode.canonicalize(sessionCode) ?? sessionCode
    }

    init(
        id: String,
        contributorID: String?,
        subjectKey: String,
        subjectTitle: String,
        title: String,
        sessionCode: String,
        sourceImageHash: String?,
        sourceSubjectTitle: String?,
        boundary1: Double,
        boundary2: Double,
        boundary3: Double,
        boundary4: Double,
        boundary5: Double,
        boundary6: Double,
        boundary7: Double,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.contributorID = contributorID
        self.subjectKey = subjectKey
        self.subjectTitle = subjectTitle
        self.title = title
        self.sessionCode = sessionCode
        self.sourceImageHash = sourceImageHash
        self.sourceSubjectTitle = sourceSubjectTitle
        self.boundary1 = boundary1
        self.boundary2 = boundary2
        self.boundary3 = boundary3
        self.boundary4 = boundary4
        self.boundary5 = boundary5
        self.boundary6 = boundary6
        self.boundary7 = boundary7
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(sharedBoundarySet entry: GradeBoundarySet) {
        guard
            entry.kind == .sessionImport,
            let subject = entry.subject,
            let sessionCode = entry.normalizedSessionCode
        else {
            return nil
        }

        let subjectKey = subject.sharedCatalogKey
        guard !subjectKey.isEmpty else { return nil }

        self.init(
            id: Self.identifier(subjectKey: subjectKey, sessionCode: sessionCode),
            contributorID: entry.ownerId,
            subjectKey: subjectKey,
            subjectTitle: subject.name,
            title: entry.title,
            sessionCode: sessionCode,
            sourceImageHash: entry.sourceImageHash,
            sourceSubjectTitle: entry.sourceSubjectTitle,
            boundary1: entry.boundary1,
            boundary2: entry.boundary2,
            boundary3: entry.boundary3,
            boundary4: entry.boundary4,
            boundary5: entry.boundary5,
            boundary6: entry.boundary6,
            boundary7: entry.boundary7,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt
        )
    }

    static func identifier(subjectKey: String, sessionCode: String) -> String {
        let canonicalCode = GradeBoundarySessionCode.canonicalize(sessionCode) ?? sessionCode
        return "\(subjectKey)::\(canonicalCode)"
    }
}

struct RemoteMarkEntry: Codable {
    let id: UUID
    let ownerID: String
    let subjectID: UUID?
    let paperName: String
    let examDate: Date
    let scoredMarks: Double
    let totalMarks: Double
    let notes: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case subjectID = "subject_id"
        case paperName = "paper_name"
        case examDate = "exam_date"
        case scoredMarks = "scored_marks"
        case totalMarks = "total_marks"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(entry: MarkEntry) {
        self.id = entry.id
        self.ownerID = entry.ownerId
        self.subjectID = entry.subject?.id
        self.paperName = entry.paperName
        self.examDate = entry.examDate
        self.scoredMarks = entry.scoredMarks
        self.totalMarks = entry.totalMarks
        self.notes = entry.notes
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
    }
}

struct RemoteMistakeEntry: Codable {
    let id: UUID
    let ownerID: String
    let subjectID: UUID?
    let markEntryID: UUID?
    let title: String
    let marksLost: Double?
    let note: String
    let photoPath: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case subjectID = "subject_id"
        case markEntryID = "mark_entry_id"
        case title
        case marksLost = "marks_lost"
        case note
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(entry: MistakeEntry) {
        self.id = entry.id
        self.ownerID = entry.ownerId
        self.subjectID = entry.subject?.id
        self.markEntryID = entry.markEntry?.id
        self.title = entry.title
        self.marksLost = entry.marksLost
        self.note = entry.note
        self.photoPath = entry.photoPath
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
    }
}
