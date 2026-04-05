import Foundation

enum GradeBoundarySessionCode {
    static func canonicalize(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let uppercased = trimmed
            .uppercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        let pattern = #"([MN])\s*(\d{2,4})\s*TZ\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return uppercased.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }

        let fullRange = NSRange(uppercased.startIndex..<uppercased.endIndex, in: uppercased)
        guard
            let match = regex.firstMatch(in: uppercased, range: fullRange),
            let sessionRange = Range(match.range(at: 1), in: uppercased),
            let yearRange = Range(match.range(at: 2), in: uppercased),
            let timezoneRange = Range(match.range(at: 3), in: uppercased)
        else {
            return uppercased.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }

        let session = String(uppercased[sessionRange])
        let yearToken = String(uppercased[yearRange])
        let timezone = String(uppercased[timezoneRange])
        let normalizedYear = yearToken.count == 4 ? String(yearToken.suffix(2)) : yearToken
        return "\(session)\(normalizedYear) TZ\(timezone)"
    }
}

struct GradeBoundaryMatch {
    let set: GradeBoundarySet
    let grade: Int
    let thresholdPercentage: Double
}

enum GradeBoundaryResolver {
    static func resolvedBoundary(for entry: MarkEntry) -> GradeBoundaryMatch? {
        resolvedBoundary(
            percentage: entry.percentage,
            paperName: entry.paperName,
            subject: entry.subject
        )
    }

    static func resolvedBoundary(
        percentage: Double,
        paperName: String,
        subject: Subject?
    ) -> GradeBoundaryMatch? {
        guard let subject else { return nil }

        if let sessionCode = PaperNameFormatter.boundarySessionCode(for: paperName),
           let imported = subject.importedGradeBoundarySets.first(where: { $0.normalizedSessionCode == sessionCode }),
           let match = gradeMatch(for: percentage, using: imported.thresholds) {
            return GradeBoundaryMatch(set: imported, grade: match.grade, thresholdPercentage: match.thresholdPercentage)
        }

        if let manual = subject.manualGradeBoundarySet,
           let match = gradeMatch(for: percentage, using: manual.thresholds) {
            return GradeBoundaryMatch(set: manual, grade: match.grade, thresholdPercentage: match.thresholdPercentage)
        }

        return nil
    }

    static func gradeMatch(
        for percentage: Double,
        using thresholds: GradeBoundaryThresholds
    ) -> (grade: Int, thresholdPercentage: Double)? {
        guard thresholds.isStrictlyAscending else { return nil }

        let thresholdPairs = thresholds.gradePairsDescending.map { pair in
            (grade: pair.grade, thresholdPercentage: pair.minimumMark)
        }

        for pair in thresholdPairs where percentage >= pair.thresholdPercentage {
            return pair
        }
        return (1, thresholds.grade1)
    }
}
