import Foundation

struct TrendPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let percentage: Double
    let subjectId: UUID?
    let subjectName: String

    var subjectFilterKey: String {
        subjectId?.uuidString.lowercased() ?? "unknown"
    }
}

struct SubjectAverage: Identifiable, Equatable {
    let subjectName: String
    let averagePercentage: Double

    var id: String { subjectName }
}

enum AnalyticsCalculator {
    static func trendPoints(from entries: [MarkEntry]) -> [TrendPoint] {
        entries
            .sorted { $0.examDate < $1.examDate }
            .map {
                TrendPoint(
                    id: $0.id,
                    date: $0.examDate,
                    percentage: $0.percentage,
                    subjectId: $0.subject?.id,
                    subjectName: $0.subject?.name ?? "Unknown"
                )
            }
    }

    static func subjectAverages(from entries: [MarkEntry]) -> [SubjectAverage] {
        let grouped = Dictionary(grouping: entries) { $0.subject?.name ?? "Unknown" }
        return grouped
            .map { key, values in
                let average = values.map(\.percentage).reduce(0, +) / Double(values.count)
                return SubjectAverage(subjectName: key, averagePercentage: average)
            }
            .sorted { $0.averagePercentage > $1.averagePercentage }
    }
}
