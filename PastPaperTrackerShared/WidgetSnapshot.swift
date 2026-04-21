import Foundation
import SwiftUI
import UIKit

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
    let mistakeCount: Int
    let marksLost: Double
    let latestPercentage: Double?
    let latestPaperName: String?
    let latestExamDate: Date?
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
    let latestSubjectID: String?
    let latestSubjectName: String?
    let latestPaperName: String?
    let latestPaperPercentage: Double?
    let focusSubjectName: String?
    let focusSubjectMarksLost: Double?
    let subjectSummaries: [WidgetSubjectSnapshot]

    static let empty = WidgetDashboardSnapshot(
        generatedAt: .now,
        overallAverage: 0,
        testsLogged: 0,
        mistakesLogged: 0,
        totalMarksLost: 0,
        bestSubjectName: nil,
        bestSubjectAverage: nil,
        latestSubjectID: nil,
        latestSubjectName: nil,
        latestPaperName: nil,
        latestPaperPercentage: nil,
        focusSubjectName: nil,
        focusSubjectMarksLost: nil,
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
        latestSubjectID: "physics",
        latestSubjectName: "Physics",
        latestPaperName: "Mechanics Paper 3",
        latestPaperPercentage: 81,
        focusSubjectName: "Chemistry",
        focusSubjectMarksLost: 11,
        subjectSummaries: [
            WidgetSubjectSnapshot(
                id: "physics",
                name: "Physics",
                averagePercentage: 84,
                testCount: 5,
                mistakeCount: 3,
                marksLost: 7,
                latestPercentage: 81,
                latestPaperName: "Mechanics Paper 3",
                latestExamDate: .now,
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
                mistakeCount: 2,
                marksLost: 5,
                latestPercentage: 79,
                latestPaperName: "Calculus Paper 4",
                latestExamDate: .now.addingTimeInterval(-86400),
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
                mistakeCount: 4,
                marksLost: 11,
                latestPercentage: 70,
                latestPaperName: "Organic Paper 2",
                latestExamDate: .now.addingTimeInterval(-86400 * 2),
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

enum WidgetStudyTheme {
    static let accent = Color.dynamic(light: 0x7CC56C, dark: 0x90D67B)
    static let accentDeep = Color.dynamic(light: 0x2D6D34, dark: 0x65B86F)
    static let accentSoft = Color.dynamic(light: 0xE8F4E1, dark: 0x18241B)
    static let sky = Color.dynamic(light: 0x6EA8E8, dark: 0x82B7F2)
    static let warm = Color.dynamic(light: 0xD8AF63, dark: 0xE4BF79)
    static let rose = Color.dynamic(light: 0xD97A7D, dark: 0xE59699)
    static let ink = Color.dynamic(light: 0x171C18, dark: 0xF3F5EF)
    static let mutedText = Color.dynamic(light: 0x627066, dark: 0x93A097)
    static let tertiaryText = Color.dynamic(light: 0x899286, dark: 0x7D887F)
    static let border = Color.dynamic(light: 0xE2E6DD, dark: 0x2A332D)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color.dynamic(light: 0xFBFBF6, dark: 0x08100D),
            Color.dynamic(light: 0xF1F6EF, dark: 0x0D1713),
            Color.dynamic(light: 0xEEF1EA, dark: 0x13211B)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            accentSoft.opacity(0.92),
            Color.dynamic(light: 0xF7F8F2, dark: 0x121914),
            Color.dynamic(light: 0xFFFFFF, dark: 0x171C18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func scoreColor(for percentage: Double) -> Color {
        switch percentage {
        case ..<45:
            rose
        case ..<70:
            warm
        default:
            accent
        }
    }
}

private extension Color {
    static func dynamic(light: UInt, dark: UInt, opacity: Double = 1) -> Color {
        Color(
            uiColor: UIColor { trait in
                UIColor(
                    rgb: trait.userInterfaceStyle == .dark ? dark : light,
                    alpha: opacity
                )
            }
        )
    }
}

private extension UIColor {
    convenience init(rgb: UInt, alpha: Double = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
