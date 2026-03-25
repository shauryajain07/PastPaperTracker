import Foundation

enum ISO8601 {
    private static func formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static func string(from date: Date) -> String {
        formatter().string(from: date)
    }

    static func date(from value: String) -> Date {
        formatter().date(from: value) ?? .now
    }
}
