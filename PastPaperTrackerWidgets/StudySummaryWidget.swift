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
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        WidgetHeader(
                            eyebrow: "Pinned Subject",
                            title: subject.name,
                            subtitle: "\(subject.testCount) test\(subject.testCount == 1 ? "" : "s")"
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
                            WidgetStatItem(title: "Tests", value: "\(subject.testCount)")
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
                            subtitle: subject.latestPaperName ?? "Latest paper"
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
                            WidgetStatItem(title: "Latest", value: percentageText(subject.latestPercentage))
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
                            subtitle: subject.latestPaperName ?? "Latest paper"
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
                            WidgetStatItem(title: "Latest", value: percentageText(subject.latestPercentage))
                        ]
                    )

                    if let latestPaperName = subject.latestPaperName {
                        Text(latestPaperName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WidgetPalette.secondaryText)
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
            RuleMark(y: .value("Benchmark", 50))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(.white.opacity(0.16))

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
                                WidgetPalette.mint.opacity(0.30),
                                WidgetPalette.mint.opacity(0.02)
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
                            WidgetPalette.mint,
                            WidgetPalette.amber
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
                .symbolSize(72)
                .foregroundStyle(Color.white)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(.clear)
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
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }
            .containerBackground(for: .widget) {
                ZStack {
                    LinearGradient(
                        colors: [
                            WidgetPalette.navy,
                            WidgetPalette.deepTeal,
                            WidgetPalette.moss
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(WidgetPalette.amber.opacity(0.26))
                        .frame(width: 180, height: 180)
                        .blur(radius: 48)
                        .offset(x: 74, y: -72)

                    Circle()
                        .fill(WidgetPalette.mint.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .blur(radius: 58)
                        .offset(x: -92, y: 110)

                    LinearGradient(
                        colors: [
                            .white.opacity(0.10),
                            .clear,
                            .black.opacity(0.18)
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
                .foregroundStyle(WidgetPalette.secondaryText)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(WidgetPalette.secondaryText)
                .lineLimit(1)
        }
    }
}

private struct ScoreBadge: View {
    let value: Double?
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(WidgetPalette.secondaryText)

            Text(percentageText(value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
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
                        .foregroundStyle(WidgetPalette.secondaryText)

                    Text(item.value)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

private struct WidgetEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetHeader(eyebrow: "Subject Graph", title: title, subtitle: "Graph unavailable")

            Spacer(minLength: 0)

            Text(message)
                .font(.footnote)
                .foregroundStyle(WidgetPalette.secondaryText)

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
                    .fill(.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            }
    }
}

private enum WidgetPalette {
    static let navy = Color(red: 0.07, green: 0.10, blue: 0.19)
    static let deepTeal = Color(red: 0.08, green: 0.24, blue: 0.28)
    static let moss = Color(red: 0.21, green: 0.50, blue: 0.44)
    static let mint = Color(red: 0.66, green: 0.97, blue: 0.88)
    static let amber = Color(red: 0.97, green: 0.80, blue: 0.51)
    static let secondaryText = Color.white.opacity(0.74)
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
