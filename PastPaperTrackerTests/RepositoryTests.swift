import SwiftData
import XCTest
@testable import PastPaperTracker

@MainActor
final class RepositoryTests: XCTestCase {
    func testSubjectDeleteMovesRecordOutOfActiveList() throws {
        let container = ModelFactory.makeContainer(inMemory: true)
        let repository = SubjectRepository(context: container.mainContext)

        let subject = try repository.create(ownerId: "user-1", name: "Chemistry")

        XCTAssertEqual(try repository.fetchActive(ownerId: "user-1").count, 1)

        try repository.markDeleted(subject)

        XCTAssertEqual(try repository.fetchActive(ownerId: "user-1").count, 0)
        XCTAssertEqual(try repository.pendingDeletes(ownerId: "user-1").count, 1)
    }

    func testOwnershipMigrationMarksRecordsForUpload() throws {
        let container = ModelFactory.makeContainer(inMemory: true)
        let subjectRepository = SubjectRepository(context: container.mainContext)
        let markRepository = MarkEntryRepository(context: container.mainContext)
        let mistakeRepository = MistakeEntryRepository(context: container.mainContext)

        let subject = try subjectRepository.create(ownerId: "guest", name: "History")
        let mark = try markRepository.create(
            ownerId: "guest",
            subject: subject,
            paperName: "Paper A",
            examDate: .now,
            scoredMarks: 55,
            totalMarks: 75,
            notes: "Ran out of time"
        )
        let mistake = try mistakeRepository.create(
            ownerId: "guest",
            subject: subject,
            markEntry: mark,
            title: "Missed dates",
            marksLost: 8,
            note: "Need a better timeline review",
            photoPath: nil
        )

        try subjectRepository.migrateOwnership(from: "guest", to: "user-1")
        try markRepository.migrateOwnership(from: "guest", to: "user-1")
        try mistakeRepository.migrateOwnership(from: "guest", to: "user-1")

        XCTAssertEqual(subject.ownerId, "user-1")
        XCTAssertEqual(mark.ownerId, "user-1")
        XCTAssertEqual(mistake.ownerId, "user-1")
        XCTAssertEqual(subject.syncState, .pendingUpload)
        XCTAssertEqual(mark.syncState, .pendingUpload)
        XCTAssertEqual(mistake.syncState, .pendingUpload)
    }
}
