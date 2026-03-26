import Charts
import SwiftUI
import WidgetKit

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
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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

        return snapshot.subjectSummaries.first
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            title: subject.name,
                            subtitle: "\(subject.testCount) test\(subject.testCount == 1 ? "" : "s")"
                        )
                        Spacer(minLength: 8)
                        ScoreBadge(value: subject.latestPercentage)
                    }

                    SubjectTrendChart(points: subject.trendPoints)
                        .frame(height: 72)

                    HStack {
                        WidgetFootnote(title: "Avg", value: percentageText(subject.averagePercentage))
                        Spacer()
                        WidgetFootnote(title: "Latest", value: percentageText(subject.latestPercentage))
                    }
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
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            title: subject.name,
                            subtitle: subject.latestPaperName ?? "Latest paper"
                        )
                        Spacer(minLength: 12)
                        ScoreBadge(value: subject.latestPercentage)
                    }

                    SubjectTrendChart(points: subject.trendPoints)
                        .frame(height: 110)

                    HStack {
                        WidgetFootnote(title: "Average", value: percentageText(subject.averagePercentage))
                        Spacer()
                        WidgetFootnote(title: "Tests", value: "\(subject.testCount)")
                        Spacer()
                        WidgetFootnote(title: "Latest", value: percentageText(subject.latestPercentage))
                    }
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
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            title: subject.name,
                            subtitle: subject.latestPaperName ?? "Latest paper"
                        )
                        Spacer(minLength: 12)
                        ScoreBadge(value: subject.latestPercentage)
                    }

                    SubjectTrendChart(points: subject.trendPoints)
                        .frame(height: 150)

                    HStack(spacing: 12) {
                        WidgetMetricPill(title: "Average", value: percentageText(subject.averagePercentage))
                        WidgetMetricPill(title: "Tests", value: "\(subject.testCount)")
                        WidgetMetricPill(title: "Latest", value: percentageText(subject.latestPercentage))
                    }

                    if let latestPaperName = subject.latestPaperName {
                        Text(latestPaperName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                    }
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
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.05)
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
                            Color.white,
                            Color(red: 0.98, green: 0.82, blue: 0.48)
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
                .symbolSize(48)
                .foregroundStyle(Color.white)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct WidgetSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.15, blue: 0.28),
                        Color(red: 0.10, green: 0.30, blue: 0.32),
                        Color(red: 0.24, green: 0.60, blue: 0.53)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

private struct WidgetHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(1)

            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

private struct ScoreBadge: View {
    let value: Double?

    var body: some View {
        Text(percentageText(value))
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
    }
}

private struct WidgetFootnote: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

private struct WidgetMetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WidgetEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(title: title, subtitle: "Graph unavailable")

            Spacer(minLength: 0)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.80))

            Spacer(minLength: 0)
        }
    }
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
