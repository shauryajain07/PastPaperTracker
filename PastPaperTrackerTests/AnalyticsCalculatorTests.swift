import XCTest
@testable import PastPaperTracker

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
}
