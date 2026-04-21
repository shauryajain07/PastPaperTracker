import Charts
import SwiftUI
import WidgetKit

private enum WidgetRefreshPolicy {
    static var nextRefresh: Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now.addingTimeInterval(7200)
    }
}

struct StudySummaryEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetDashboardSnapshot
}

struct StudySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudySummaryEntry {
        StudySummaryEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudySummaryEntry) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? (context.isPreview ? .sample : .empty)
        completion(StudySummaryEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudySummaryEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? .empty
        let entry = StudySummaryEntry(date: .now, snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(WidgetRefreshPolicy.nextRefresh)))
    }
}

struct SubjectTrendEntry: TimelineEntry {
    let date: Date
    let configuration: SubjectGraphConfigurationIntent
    let snapshot: WidgetDashboardSnapshot
    let subject: WidgetSubjectSnapshot?
    let selectedSubjectName: String?
}

struct SubjectTrendProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SubjectTrendEntry {
        makeEntry(for: SubjectGraphConfigurationIntent(), using: .sample)
    }

    func snapshot(for configuration: SubjectGraphConfigurationIntent, in context: Context) async -> SubjectTrendEntry {
        makeEntry(
            for: configuration,
            using: WidgetSnapshotStore.load() ?? (context.isPreview ? .sample : .empty)
        )
    }

    func timeline(for configuration: SubjectGraphConfigurationIntent, in context: Context) async -> Timeline<SubjectTrendEntry> {
        let entry = makeEntry(for: configuration, using: WidgetSnapshotStore.load() ?? .empty)
        return Timeline(entries: [entry], policy: .after(WidgetRefreshPolicy.nextRefresh))
    }

    private func makeEntry(
        for configuration: SubjectGraphConfigurationIntent,
        using snapshot: WidgetDashboardSnapshot
    ) -> SubjectTrendEntry {
        SubjectTrendEntry(
            date: .now,
            configuration: configuration,
            snapshot: snapshot,
            subject: resolvedSubject(from: snapshot, selection: configuration.subject),
            selectedSubjectName: configuration.subject?.name
        )
    }

    private func resolvedSubject(
        from snapshot: WidgetDashboardSnapshot,
        selection: WidgetSubjectEntity?
    ) -> WidgetSubjectSnapshot? {
        if let selection {
            return snapshot.subjectSummaries.first { $0.id == selection.id }
        }

        if let latestSubjectID = snapshot.latestSubjectID {
            return snapshot.subjectSummaries.first { $0.id == latestSubjectID }
        }

        return snapshot.subjectSummaries.first
    }
}

struct StudySummaryWidget: Widget {
    private let kind = "StudySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudySummaryProvider()) { entry in
            StudySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Revision Summary")
        .description("See your average, latest result, and biggest focus area right from the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SubjectTrendWidget: Widget {
    private let kind = "SubjectTrendWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SubjectGraphConfigurationIntent.self,
            provider: SubjectTrendProvider()
        ) { entry in
            SubjectTrendWidgetView(entry: entry)
        }
        .configurationDisplayName("Subject Graph")
        .description("Pick a subject and track its score trend from the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct StudySummaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StudySummaryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StudySummarySmallView(entry: entry)
        default:
            StudySummaryMediumView(entry: entry)
        }
    }
}

private struct StudySummarySmallView: View {
    let entry: StudySummaryEntry

    var body: some View {
        WidgetSurface {
            if entry.snapshot.testsLogged > 0 {
                VStack(alignment: .leading, spacing: 14) {
                    WidgetHeader(
                        eyebrow: "Revision Snapshot",
                        title: "Overall",
                        subtitle: latestSummary(snapshot: entry.snapshot)
                    )

                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(percentageText(entry.snapshot.overallAverage))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetStudyTheme.ink)
                            .contentTransition(.numericText())

                        Text("avg")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetStudyTheme.mutedText)
                    }

                    SummaryHighlightCard(
                        title: "Focus",
                        value: entry.snapshot.focusSubjectName ?? "Stay consistent",
                        detail: focusSummary(snapshot: entry.snapshot),
                        tint: WidgetStudyTheme.rose
                    )

                    WidgetStatsBar(
                        items: [
                            WidgetStatItem(title: "Tests", value: "\(entry.snapshot.testsLogged)"),
                            WidgetStatItem(title: "Mistakes", value: "\(entry.snapshot.mistakesLogged)")
                        ]
                    )
                }
            } else {
                WidgetEmptyState(
                    title: "Revision Summary",
                    message: "Open the app and log your first paper to bring this widget to life."
                )
            }
        }
    }
}

private struct StudySummaryMediumView: View {
    let entry: StudySummaryEntry

    var body: some View {
        WidgetSurface {
            if entry.snapshot.testsLogged > 0 {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        WidgetHeader(
                            eyebrow: "Revision Snapshot",
                            title: percentageText(entry.snapshot.overallAverage),
                            subtitle: latestSummary(snapshot: entry.snapshot)
                        )

                        Spacer(minLength: 8)

                        ScoreBadge(value: entry.snapshot.latestPaperPercentage, label: "Latest")
                    }

                    HStack(spacing: 12) {
                        SummaryHighlightCard(
                            title: "Best Subject",
                            value: entry.snapshot.bestSubjectName ?? "No subject yet",
                            detail: entry.snapshot.bestSubjectAverage.map {
                                "\(percentageText($0)) average"
                            } ?? "Keep logging results to surface a leader.",
                            tint: WidgetStudyTheme.accent
                        )

                        SummaryHighlightCard(
                            title: "Focus Area",
                            value: entry.snapshot.focusSubjectName ?? "No weak spot yet",
                            detail: focusSummary(snapshot: entry.snapshot),
                            tint: WidgetStudyTheme.rose
                        )
                    }

                    WidgetStatsBar(
                        items: [
                            WidgetStatItem(title: "Tests", value: "\(entry.snapshot.testsLogged)"),
                            WidgetStatItem(title: "Mistakes", value: "\(entry.snapshot.mistakesLogged)"),
                            WidgetStatItem(title: "Marks Lost", value: marksLostText(entry.snapshot.totalMarksLost))
                        ]
                    )
                }
            } else {
                WidgetEmptyState(
                    title: "Revision Summary",
                    message: "Open the app and log your first paper to bring this widget to life."
                )
            }
        }
    }
}

private struct SubjectTrendWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SubjectTrendEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SubjectTrendSmallView(entry: entry)
        case .systemLarge:
            SubjectTrendLargeView(entry: entry)
        default:
            SubjectTrendMediumView(entry: entry)
        }
    }
}

private struct SubjectTrendSmallView: View {
    let entry: SubjectTrendEntry

    var body: some View {
        WidgetSurface {
            if let subject = entry.subject {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            eyebrow: "Pinned Subject",
                            title: subject.name,
                            subtitle: subject.latestPaperName ?? latestSubjectSubtitle(subject)
                        )

                        Spacer(minLength: 8)

                        ScoreBadge(value: subject.latestPercentage, label: "Latest")
                    }

                    WidgetChartFrame {
                        SubjectTrendChart(points: subject.trendPoints)
                    }
                    .frame(height: 72)

                    WidgetStatsBar(
                        items: [
                            WidgetStatItem(title: "Average", value: percentageText(subject.averagePercentage)),
                            WidgetStatItem(title: "Mistakes", value: "\(subject.mistakeCount)")
                        ]
                    )
                }
            } else {
                WidgetEmptyState(
                    title: entry.selectedSubjectName ?? "Select a subject",
                    message: emptyStateMessage(snapshot: entry.snapshot, selectedSubjectName: entry.selectedSubjectName)
                )
            }
        }
    }
}

private struct SubjectTrendMediumView: View {
    let entry: SubjectTrendEntry

    var body: some View {
        WidgetSurface {
            if let subject = entry.subject {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            eyebrow: "Subject Graph",
                            title: subject.name,
                            subtitle: subject.latestPaperName ?? latestSubjectSubtitle(subject)
                        )

                        Spacer(minLength: 12)

                        ScoreBadge(value: subject.latestPercentage, label: "Latest")
                    }

                    WidgetChartFrame {
                        SubjectTrendChart(points: subject.trendPoints)
                    }
                    .frame(height: 110)

                    WidgetStatsBar(
                        items: [
                            WidgetStatItem(title: "Average", value: percentageText(subject.averagePercentage)),
                            WidgetStatItem(title: "Tests", value: "\(subject.testCount)"),
                            WidgetStatItem(title: "Marks Lost", value: marksLostText(subject.marksLost))
                        ]
                    )
                }
            } else {
                WidgetEmptyState(
                    title: entry.selectedSubjectName ?? "Subject graph",
                    message: emptyStateMessage(snapshot: entry.snapshot, selectedSubjectName: entry.selectedSubjectName)
                )
            }
        }
    }
}

private struct SubjectTrendLargeView: View {
    let entry: SubjectTrendEntry

    var body: some View {
        WidgetSurface {
            if let subject = entry.subject {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            eyebrow: "Subject Graph",
                            title: subject.name,
                            subtitle: subject.latestPaperName ?? latestSubjectSubtitle(subject)
                        )

                        Spacer(minLength: 12)

                        ScoreBadge(value: subject.latestPercentage, label: "Latest")
                    }

                    WidgetChartFrame {
                        SubjectTrendChart(points: subject.trendPoints)
                    }
                    .frame(height: 150)

                    WidgetStatsBar(
                        items: [
                            WidgetStatItem(title: "Average", value: percentageText(subject.averagePercentage)),
                            WidgetStatItem(title: "Tests", value: "\(subject.testCount)"),
                            WidgetStatItem(title: "Mistakes", value: "\(subject.mistakeCount)"),
                            WidgetStatItem(title: "Marks Lost", value: marksLostText(subject.marksLost))
                        ]
                    )

                    Text(subjectFootnote(subject))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WidgetStudyTheme.mutedText)
                        .lineLimit(2)
                }
            } else {
                WidgetEmptyState(
                    title: entry.selectedSubjectName ?? "Subject graph",
                    message: emptyStateMessage(snapshot: entry.snapshot, selectedSubjectName: entry.selectedSubjectName)
                )
            }
        }
    }
}

private struct SubjectTrendChart: View {
    let points: [WidgetTrendPointSnapshot]

    var body: some View {
        Chart {
            RuleMark(y: .value("Benchmark", 50))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(WidgetStudyTheme.tertiaryText.opacity(0.35))

            if points.count > 1 {
                ForEach(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Percentage", point.percentage)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                WidgetStudyTheme.accent.opacity(0.26),
                                WidgetStudyTheme.sky.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Percentage", point.percentage)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            WidgetStudyTheme.accent,
                            WidgetStudyTheme.sky
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }

            if let latestPoint = points.last {
                PointMark(
                    x: .value("Date", latestPoint.date),
                    y: .value("Percentage", latestPoint.percentage)
                )
                .symbolSize(70)
                .foregroundStyle(WidgetStudyTheme.scoreColor(for: latestPoint.percentage))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
    }
}

private struct WidgetSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay {
                ContainerRelativeShape()
                    .stroke(WidgetStudyTheme.border.opacity(0.65), lineWidth: 1)
            }
            .containerBackground(for: .widget) {
                ZStack {
                    WidgetStudyTheme.backgroundGradient

                    Circle()
                        .fill(WidgetStudyTheme.accent.opacity(0.14))
                        .frame(width: 180, height: 180)
                        .blur(radius: 56)
                        .offset(x: 92, y: -88)

                    Circle()
                        .fill(WidgetStudyTheme.sky.opacity(0.12))
                        .frame(width: 220, height: 220)
                        .blur(radius: 64)
                        .offset(x: -100, y: 120)

                    Ellipse()
                        .fill(WidgetStudyTheme.warm.opacity(0.10))
                        .frame(width: 220, height: 140)
                        .blur(radius: 54)
                        .offset(x: -20, y: -10)

                    LinearGradient(
                        colors: [
                            .white.opacity(0.24),
                            .clear,
                            WidgetStudyTheme.accentDeep.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
    }
}

private struct WidgetHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(WidgetStudyTheme.tertiaryText)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetStudyTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(WidgetStudyTheme.mutedText)
                .lineLimit(2)
        }
    }
}

private struct ScoreBadge: View {
    let value: Double?
    let label: String

    var body: some View {
        let tint = WidgetStudyTheme.scoreColor(for: value ?? 0)

        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(WidgetStudyTheme.mutedText)

            Text(percentageText(value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetStudyTheme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

private struct SummaryHighlightCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(WidgetStudyTheme.tertiaryText)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetStudyTheme.ink)
                .lineLimit(1)

            Text(detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(WidgetStudyTheme.mutedText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                }
        }
    }
}

private struct WidgetStatItem: Identifiable {
    var id: String { title }
    let title: String
    let value: String
}

private struct WidgetStatsBar: View {
    let items: [WidgetStatItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.0)
                        .foregroundStyle(WidgetStudyTheme.tertiaryText)

                    Text(item.value)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WidgetStudyTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(WidgetStudyTheme.border.opacity(0.75))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.56))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WidgetStudyTheme.border.opacity(0.7), lineWidth: 1)
                }
        }
    }
}

private struct WidgetEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetHeader(eyebrow: "Past Paper Tracker", title: title, subtitle: "Widget waiting for data")

            Spacer(minLength: 0)

            Text(message)
                .font(.footnote)
                .foregroundStyle(WidgetStudyTheme.mutedText)

            Spacer(minLength: 0)
        }
    }
}

private struct WidgetChartFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.54))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(WidgetStudyTheme.border.opacity(0.7), lineWidth: 1)
                    }
            }
    }
}

private func latestSummary(snapshot: WidgetDashboardSnapshot) -> String {
    guard let latestPaperName = snapshot.latestPaperName else {
        return "Keep logging results to build your study picture."
    }

    if let latestSubjectName = snapshot.latestSubjectName {
        return "\(latestPaperName) in \(latestSubjectName)"
    }

    return latestPaperName
}

private func focusSummary(snapshot: WidgetDashboardSnapshot) -> String {
    guard let focusSubjectName = snapshot.focusSubjectName else {
        return "No obvious weak spot yet."
    }

    let marksLost = snapshot.focusSubjectMarksLost ?? 0
    if marksLost > 0 {
        return "\(marksLostText(marksLost)) drifting away in \(focusSubjectName)."
    }

    return "Most mistakes are currently in \(focusSubjectName)."
}

private func latestSubjectSubtitle(_ subject: WidgetSubjectSnapshot) -> String {
    guard let latestExamDate = subject.latestExamDate else {
        return "\(subject.testCount) test\(subject.testCount == 1 ? "" : "s")"
    }

    return WidgetDateFormatter.short.string(from: latestExamDate)
}

private func subjectFootnote(_ subject: WidgetSubjectSnapshot) -> String {
    if subject.marksLost > 0 {
        return "\(marksLostText(subject.marksLost)) tied to logged mistakes in \(subject.name)."
    }

    return "\(subject.mistakeCount) revision item\(subject.mistakeCount == 1 ? "" : "s") linked to this subject."
}

private func emptyStateMessage(snapshot: WidgetDashboardSnapshot, selectedSubjectName: String?) -> String {
    if snapshot.subjectSummaries.isEmpty {
        return "Open the app and log a paper first, then add this widget again."
    }

    if let selectedSubjectName {
        return "\(selectedSubjectName) is no longer available. Edit the widget to choose another subject."
    }

    return "Edit the widget to choose which subject trend you want to pin."
}

private func percentageText(_ value: Double?) -> String {
    guard let value else { return "--" }
    return "\(value.formatted(.number.precision(.fractionLength(0))))%"
}

private func marksLostText(_ value: Double) -> String {
    guard value > 0 else { return "--" }
    return "\(value.formatted(.number.precision(.fractionLength(0))))"
}

private enum WidgetDateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
