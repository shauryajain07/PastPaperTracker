import Foundation

struct TrendPoint: Identifiable, Equatable {
    let date: Date
    let percentage: Double

    var id: Date { date }
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
            .map { TrendPoint(date: $0.examDate, percentage: $0.percentage) }
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
