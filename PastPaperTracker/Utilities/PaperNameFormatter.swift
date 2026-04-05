import Foundation

enum PastPaperSession: String, CaseIterable, Identifiable {
    case m = "M"
    case n = "N"

    var id: String { rawValue }
}

struct StandardizedPaperNameFields: Equatable {
    var year: String
    var session: PastPaperSession
    var paperNumber: String
    var timezoneNumber: String

    init(
        year: String = "",
        session: PastPaperSession = .m,
        paperNumber: String = "",
        timezoneNumber: String = ""
    ) {
        self.year = year
        self.session = session
        self.paperNumber = paperNumber
        self.timezoneNumber = timezoneNumber
    }
}

enum PaperNameFormatter {
    static func build(from fields: StandardizedPaperNameFields) -> String {
        "\(fields.year)-\(fields.session.rawValue)-\(fields.paperNumber)-TZ\(fields.timezoneNumber)"
    }

    static func parse(_ paperName: String) -> StandardizedPaperNameFields? {
        let pattern = #"^(\d{4})-(M|N)-(\d+)-TZ(\d+)$"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: paperName,
                range: NSRange(paperName.startIndex..., in: paperName)
            ),
            match.numberOfRanges == 5,
            let yearRange = Range(match.range(at: 1), in: paperName),
            let sessionRange = Range(match.range(at: 2), in: paperName),
            let paperNumberRange = Range(match.range(at: 3), in: paperName),
            let timezoneRange = Range(match.range(at: 4), in: paperName),
            let session = PastPaperSession(rawValue: String(paperName[sessionRange]))
        else {
            return nil
        }

        return StandardizedPaperNameFields(
            year: String(paperName[yearRange]),
            session: session,
            paperNumber: String(paperName[paperNumberRange]),
            timezoneNumber: String(paperName[timezoneRange])
        )
    }

    static func defaultFields(for date: Date) -> StandardizedPaperNameFields {
        let year = Calendar.current.component(.year, from: date)
        return StandardizedPaperNameFields(year: String(year))
    }

    static func boundarySessionCode(for paperName: String) -> String? {
        guard let fields = parse(paperName) else { return nil }
        let yearSuffix = String(fields.year.suffix(2))
        return GradeBoundarySessionCode.canonicalize("\(fields.session.rawValue)\(yearSuffix) TZ\(fields.timezoneNumber)")
    }
}
