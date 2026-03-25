import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    private let ownerId: String
    @Environment(\.colorScheme) private var colorScheme
    @Query private var markEntries: [MarkEntry]
    @Query private var mistakes: [MistakeEntry]

    init(ownerId: String) {
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        _markEntries = Query(
            filter: #Predicate<MarkEntry> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.examDate, order: .reverse)]
        )
        _mistakes = Query(
            filter: #Predicate<MistakeEntry> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    private var trendPoints: [TrendPoint] {
        AnalyticsCalculator.trendPoints(from: markEntries)
    }

    private var subjectAverages: [SubjectAverage] {
        AnalyticsCalculator.subjectAverages(from: markEntries)
    }

    private var overallAverage: Double {
        guard !markEntries.isEmpty else { return 0 }
        return markEntries.map(\.percentage).reduce(0, +) / Double(markEntries.count)
    }

    private var bestSubjectSummary: String {
        guard let bestSubject = subjectAverages.first else { return "Add results" }
        return "\(bestSubject.subjectName) \(bestSubject.averagePercentage.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var totalMarksLost: Double {
        mistakes.compactMap(\.marksLost).reduce(0, +)
    }

    private var latestEntry: MarkEntry? {
        markEntries.first
    }

    private var improvementFromPrevious: Double? {
        guard markEntries.count > 1 else { return nil }
        return markEntries[0].percentage - markEntries[1].percentage
    }

    private var dashboardMessage: String {
        guard !markEntries.isEmpty else {
            return "Log your first paper to unlock trends, averages, and linked mistake review."
        }

        if let improvementFromPrevious {
            let direction = improvementFromPrevious >= 0 ? "up" : "down"
            return "Average performance is \(overallAverage.formatted(.number.precision(.fractionLength(0))))%, and your latest paper is \(direction) \(abs(improvementFromPrevious).formatted(.number.precision(.fractionLength(0)))) points from the previous one."
        }

        return "You have your first paper in place. Keep logging results to turn this into a usable trend."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection

                    if markEntries.isEmpty {
                        StudyEmptyState(
                            title: "No scores yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            message: "Add your first past paper result from the Tests tab to start seeing performance patterns."
                        )
                        .studyPanel(padding: 28)
                    } else {
                        trendSection
                        averagesSection
                    }

                    recentTestsSection
                    recentMistakesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("PAST PAPER TRACKER")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Text("Revision snapshot")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(dashboardMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StudyStatChip(
                    title: "Average",
                    value: markEntries.isEmpty ? "--" : "\(overallAverage.formatted(.number.precision(.fractionLength(0))))%",
                    systemImage: "gauge.with.dots.needle.50percent"
                )
                StudyStatChip(
                    title: "Best Subject",
                    value: bestSubjectSummary,
                    systemImage: "sparkles"
                )
                StudyStatChip(
                    title: "Tests Logged",
                    value: "\(markEntries.count)",
                    systemImage: "doc.text.magnifyingglass"
                )
                StudyStatChip(
                    title: "Mistake Load",
                    value: totalMarksLost > 0 ? "\(totalMarksLost.formatted(.number.precision(.fractionLength(0)))) marks" : "\(mistakes.count) items",
                    systemImage: "exclamationmark.bubble"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Performance Trend",
                detail: "Your latest papers, shown as percentage over time."
            )

            VStack(alignment: .leading, spacing: 16) {
                Chart(trendPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Percentage", point.percentage)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                StudyTheme.accent.opacity(0.30),
                                StudyTheme.accent.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Percentage", point.percentage)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(StudyTheme.accent)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Percentage", point.percentage)
                    )
                    .symbolSize(40)
                    .foregroundStyle(StudyTheme.accent)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .foregroundStyle(.primary.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(trendPoints.count, 4))) { value in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(height: 240)

                HStack {
                    if let latestEntry {
                        Text("Latest: \(latestEntry.paperName)")
                            .lineLimit(1)
                    } else {
                        Text("No latest paper yet")
                    }

                    Spacer(minLength: 12)

                    if let improvementFromPrevious {
                        Text(
                            improvementFromPrevious >= 0
                                ? "Up \(abs(improvementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pts"
                                : "Down \(abs(improvementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pts"
                        )
                    } else {
                        Text("Waiting for more data")
                    }
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .studyPanel()
        }
    }

    private var averagesSection: some View {
        let averages = subjectAverages

        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Subject Averages",
                detail: "Use this to see where your baseline is already strong."
            )

            VStack(spacing: 16) {
                ForEach(Array(averages.enumerated()), id: \.element.id) { index, average in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(average.subjectName)
                                .font(.headline.weight(.semibold))
                            Spacer()
                            StudyScorePill(percentage: average.averagePercentage)
                        }

                        StudyProgressBar(
                            progress: average.averagePercentage / 100,
                            tint: StudyTheme.scoreColor(for: average.averagePercentage)
                        )
                    }

                    if index < averages.count - 1 {
                        Divider()
                    }
                }
            }
            .studyPanel()
        }
    }

    private var recentTestsSection: some View {
        let recentEntries = Array(markEntries.prefix(3))

        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Recent Tests",
                detail: "Jump back into your latest papers without digging."
            )

            if recentEntries.isEmpty {
                StudyEmptyState(
                    title: "No test history yet",
                    systemImage: "doc.text",
                    message: "Your last few papers will appear here once you start logging results."
                )
                .studyPanel(padding: 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            TestDetailView(entry: entry, ownerId: ownerId)
                        } label: {
                            StudyTestRowContent(entry: entry)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        if index < recentEntries.count - 1 {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }
                .studyPanel(padding: 0)
            }
        }
    }

    private var recentMistakesSection: some View {
        let recentMistakes = Array(mistakes.prefix(3))

        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Recent Mistakes",
                detail: "Keep the errors that still cost marks within easy reach."
            )

            if recentMistakes.isEmpty {
                StudyEmptyState(
                    title: "No mistakes logged yet",
                    systemImage: "exclamationmark.bubble",
                    message: "Mistakes you capture from papers will show up here for quick review."
                )
                .studyPanel(padding: 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentMistakes.enumerated()), id: \.element.id) { index, mistake in
                        NavigationLink {
                            MistakeDetailView(mistake: mistake, ownerId: ownerId)
                        } label: {
                            StudyMistakeRowContent(mistake: mistake)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        if index < recentMistakes.count - 1 {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }
                .studyPanel(padding: 0)
            }
        }
    }
}
