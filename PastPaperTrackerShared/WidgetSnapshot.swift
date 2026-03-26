import Foundation

enum WidgetSharing {
    static let appGroupIdentifier = "group.com.shauryajain.PastPaperTracker"
    static let dashboardSnapshotKey = "dashboardSnapshot"
}

struct WidgetTrendPointSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let date: Date
    let percentage: Double
    let paperName: String
}

struct WidgetSubjectSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let averagePercentage: Double
    let testCount: Int
    let latestPercentage: Double?
    let latestPaperName: String?
    let trendPoints: [WidgetTrendPointSnapshot]
}

struct WidgetDashboardSnapshot: Codable, Hashable {
    let generatedAt: Date
    let overallAverage: Double
    let testsLogged: Int
    let mistakesLogged: Int
    let totalMarksLost: Double
    let bestSubjectName: String?
    let bestSubjectAverage: Double?
    let latestPaperName: String?
    let latestPaperPercentage: Double?
    let subjectSummaries: [WidgetSubjectSnapshot]

    static let empty = WidgetDashboardSnapshot(
        generatedAt: .now,
        overallAverage: 0,
        testsLogged: 0,
        mistakesLogged: 0,
        totalMarksLost: 0,
        bestSubjectName: nil,
        bestSubjectAverage: nil,
        latestPaperName: nil,
        latestPaperPercentage: nil,
        subjectSummaries: []
    )

    static let sample = WidgetDashboardSnapshot(
        generatedAt: .now,
        overallAverage: 78,
        testsLogged: 12,
        mistakesLogged: 9,
        totalMarksLost: 23,
        bestSubjectName: "Physics",
        bestSubjectAverage: 84,
        latestPaperName: "Mechanics Paper 3",
        latestPaperPercentage: 81,
        subjectSummaries: [
            WidgetSubjectSnapshot(
                id: "physics",
                name: "Physics",
                averagePercentage: 84,
                testCount: 5,
                latestPercentage: 81,
                latestPaperName: "Mechanics Paper 3",
                trendPoints: [
                    WidgetTrendPointSnapshot(id: "physics-1", date: .now.addingTimeInterval(-86400 * 28), percentage: 62, paperName: "Kinematics Paper 1"),
                    WidgetTrendPointSnapshot(id: "physics-2", date: .now.addingTimeInterval(-86400 * 21), percentage: 71, paperName: "Forces Paper 2"),
                    WidgetTrendPointSnapshot(id: "physics-3", date: .now.addingTimeInterval(-86400 * 14), percentage: 76, paperName: "Electricity Paper 1"),
                    WidgetTrendPointSnapshot(id: "physics-4", date: .now.addingTimeInterval(-86400 * 7), percentage: 88, paperName: "Waves Paper 2"),
                    WidgetTrendPointSnapshot(id: "physics-5", date: .now, percentage: 81, paperName: "Mechanics Paper 3")
                ]
            ),
            WidgetSubjectSnapshot(
                id: "maths",
                name: "Maths",
                averagePercentage: 77,
                testCount: 4,
                latestPercentage: 79,
                latestPaperName: "Calculus Paper 4",
                trendPoints: [
                    WidgetTrendPointSnapshot(id: "maths-1", date: .now.addingTimeInterval(-86400 * 25), percentage: 68, paperName: "Algebra Paper 1"),
                    WidgetTrendPointSnapshot(id: "maths-2", date: .now.addingTimeInterval(-86400 * 16), percentage: 74, paperName: "Geometry Paper 2"),
                    WidgetTrendPointSnapshot(id: "maths-3", date: .now.addingTimeInterval(-86400 * 8), percentage: 87, paperName: "Statistics Paper 1"),
                    WidgetTrendPointSnapshot(id: "maths-4", date: .now.addingTimeInterval(-86400 * 1), percentage: 79, paperName: "Calculus Paper 4")
                ]
            ),
            WidgetSubjectSnapshot(
                id: "chemistry",
                name: "Chemistry",
                averagePercentage: 72,
                testCount: 3,
                latestPercentage: 70,
                latestPaperName: "Organic Paper 2",
                trendPoints: [
                    WidgetTrendPointSnapshot(id: "chemistry-1", date: .now.addingTimeInterval(-86400 * 24), percentage: 66, paperName: "Bonding Paper 1"),
                    WidgetTrendPointSnapshot(id: "chemistry-2", date: .now.addingTimeInterval(-86400 * 11), percentage: 80, paperName: "Rates Paper 3"),
                    WidgetTrendPointSnapshot(id: "chemistry-3", date: .now.addingTimeInterval(-86400 * 2), percentage: 70, paperName: "Organic Paper 2")
                ]
            )
        ]
    )
}

enum WidgetSnapshotStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetSharing.appGroupIdentifier) ?? .standard
    }

    static func load() -> WidgetDashboardSnapshot? {
        guard let data = defaults.data(forKey: WidgetSharing.dashboardSnapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetDashboardSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetDashboardSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: WidgetSharing.dashboardSnapshotKey)
    }

    static func clear() {
        defaults.removeObject(forKey: WidgetSharing.dashboardSnapshotKey)
    }
}
