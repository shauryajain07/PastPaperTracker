import XCTest
@testable import PastPaperTracker

@MainActor
final class AnalyticsCalculatorTests: XCTestCase {
    func testTrendPointsAreSortedChronologically() {
        let subject = Subject(ownerId: "user-1", name: "Math")
        let older = MarkEntry(ownerId: "user-1", subject: subject, paperName: "Paper 1", examDate: .distantPast, scoredMarks: 60, totalMarks: 100)
        let newer = MarkEntry(ownerId: "user-1", subject: subject, paperName: "Paper 2", examDate: .now, scoredMarks: 80, totalMarks: 100)

        let result = AnalyticsCalculator.trendPoints(from: [newer, older])

        XCTAssertEqual(result.count, 2)
        XCTAssertLessThan(result[0].date, result[1].date)
        XCTAssertEqual(result[0].percentage, 60)
        XCTAssertEqual(result[1].percentage, 80)
        XCTAssertEqual(result[0].subjectName, "Math")
        XCTAssertEqual(result[1].subjectName, "Math")
    }

    func testSubjectAveragesGroupBySubjectName() {
        let math = Subject(ownerId: "user-1", name: "Math")
        let physics = Subject(ownerId: "user-1", name: "Physics")
        let entries = [
            MarkEntry(ownerId: "user-1", subject: math, paperName: "A", scoredMarks: 80, totalMarks: 100),
            MarkEntry(ownerId: "user-1", subject: math, paperName: "B", scoredMarks: 60, totalMarks: 100),
            MarkEntry(ownerId: "user-1", subject: physics, paperName: "C", scoredMarks: 90, totalMarks: 100),
        ]

        let averages = AnalyticsCalculator.subjectAverages(from: entries)

        XCTAssertEqual(averages.count, 2)
        XCTAssertEqual(averages.first?.subjectName, "Physics")
        XCTAssertEqual(averages.first?.averagePercentage, 90)
        XCTAssertEqual(averages.last?.averagePercentage, 70)
    }

    func testIBGradePointsIncludeOnlyResolvedEntriesAndSortChronologically() {
        let subject = Subject(ownerId: "user-1", name: "Physics")
        let manual = GradeBoundarySet(
            ownerId: "user-1",
            subject: subject,
            title: "Default",
            kind: .manualDefault,
            thresholds: GradeBoundaryThresholds(grade1: 0, grade2: 12, grade3: 24, grade4: 35, grade5: 49, grade6: 63, grade7: 75)
        )
        subject.gradeBoundarySets = [manual]

        let older = MarkEntry(
            ownerId: "user-1",
            subject: subject,
            paperName: "Paper 1",
            examDate: .distantPast,
            scoredMarks: 76,
            totalMarks: 100
        )
        let newer = MarkEntry(
            ownerId: "user-1",
            subject: subject,
            paperName: "Paper 2",
            examDate: .now,
            scoredMarks: 64,
            totalMarks: 100
        )
        let unresolved = MarkEntry(
            ownerId: "user-1",
            subject: Subject(ownerId: "user-1", name: "History"),
            paperName: "Paper 3",
            examDate: .now,
            scoredMarks: 90,
            totalMarks: 100
        )

        let result = AnalyticsCalculator.ibGradePoints(from: [newer, unresolved, older])

        XCTAssertEqual(result.count, 2)
        XCTAssertLessThan(result[0].date, result[1].date)
        XCTAssertEqual(result[0].grade, 7)
        XCTAssertEqual(result[1].grade, 6)
        XCTAssertEqual(result[1].paperName, "Paper 2")
        XCTAssertEqual(result[0].subjectName, "Physics")
    }
}
