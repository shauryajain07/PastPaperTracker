import Foundation

struct RemoteSubject: Codable {
    let id: UUID
    let ownerID: String
    let name: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, ownerID: String, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(subject: Subject) {
        self.init(
            id: subject.id,
            ownerID: subject.ownerId,
            name: subject.name,
            createdAt: subject.createdAt,
            updatedAt: subject.updatedAt
        )
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
