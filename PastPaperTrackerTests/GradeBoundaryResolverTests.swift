import XCTest
@testable import PastPaperTracker

@MainActor
final class GradeBoundaryResolverTests: XCTestCase {
    func testBoundarySessionCodeUsesPaperYearSuffixAndTimezone() {
        let code = PaperNameFormatter.boundarySessionCode(for: "2025-M-12-TZ2")

        XCTAssertEqual(code, "M25 TZ2")
    }

    func testResolvedBoundaryPrefersImportedSessionBoundary() {
        let subject = Subject(ownerId: "user-1", name: "Math")
        let manual = GradeBoundarySet(
            ownerId: "user-1",
            subject: subject,
            title: "Default",
            kind: .manualDefault,
            thresholds: GradeBoundaryThresholds(grade1: 0, grade2: 10, grade3: 20, grade4: 30, grade5: 40, grade6: 50, grade7: 60)
        )
        let imported = GradeBoundarySet(
            ownerId: "user-1",
            subject: subject,
            title: "M25 TZ1",
            kind: .sessionImport,
            sessionCode: "M25 TZ1",
            thresholds: GradeBoundaryThresholds(grade1: 0, grade2: 15, grade3: 25, grade4: 35, grade5: 45, grade6: 55, grade7: 65)
        )
        subject.gradeBoundarySets = [manual, imported]

        let result = GradeBoundaryResolver.resolvedBoundary(
            percentage: 56,
            paperName: "2025-M-12-TZ1",
            subject: subject
        )

        XCTAssertEqual(result?.grade, 6)
        XCTAssertEqual(result?.set.title, "M25 TZ1")
        XCTAssertEqual(result?.thresholdPercentage, 55)
    }

    func testResolvedBoundaryFallsBackToManualBoundary() {
        let subject = Subject(ownerId: "user-1", name: "Physics")
        let manual = GradeBoundarySet(
            ownerId: "user-1",
            subject: subject,
            title: "Default",
            kind: .manualDefault,
            thresholds: GradeBoundaryThresholds(grade1: 0, grade2: 12, grade3: 24, grade4: 35, grade5: 49, grade6: 63, grade7: 75)
        )
        subject.gradeBoundarySets = [manual]

        let result = GradeBoundaryResolver.resolvedBoundary(
            percentage: 64,
            paperName: "2025-N-21-TZ3",
            subject: subject
        )

        XCTAssertEqual(result?.grade, 6)
        XCTAssertEqual(result?.set.kind, .manualDefault)
    }
}
