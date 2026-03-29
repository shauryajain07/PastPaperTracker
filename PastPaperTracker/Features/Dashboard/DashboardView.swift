import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    private let ownerId: String
    @Environment(\.colorScheme) private var colorScheme
    @Query private var subjects: [Subject]
    @Query private var markEntries: [MarkEntry]
    @Query private var mistakes: [MistakeEntry]
    @State private var selectedSubjectFilter = "all"
    @State private var showingNewTestSheet = false
    @State private var showingNewMistakeSheet = false

    init(ownerId: String) {
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        _subjects = Query(
            filter: #Predicate<Subject> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.name)]
        )
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

    private var filteredTrendPoints: [TrendPoint] {
        guard effectiveSubjectFilter != "all" else { return trendPoints }
        return trendPoints.filter { $0.subjectFilterKey == effectiveSubjectFilter }
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

    private var effectiveSubjectFilter: String {
        guard selectedSubjectFilter != "all" else { return "all" }
        let hasSubject = subjects.contains { $0.id.uuidString.lowercased() == selectedSubjectFilter }
        return hasSubject ? selectedSubjectFilter : "all"
    }

    private var selectedSubject: Subject? {
        guard effectiveSubjectFilter != "all" else { return nil }
        return subjects.first { $0.id.uuidString.lowercased() == effectiveSubjectFilter }
    }

    private var focusLabel: String {
        selectedSubject?.name ?? "All Subjects"
    }

    private var focusScopeDescription: String {
        selectedSubject == nil ? "across all subjects" : "in \(focusLabel)"
    }

    private var focusMarkEntries: [MarkEntry] {
        guard effectiveSubjectFilter != "all" else { return markEntries }
        return markEntries.filter { $0.subject?.id.uuidString.lowercased() == effectiveSubjectFilter }
    }

    private var focusMistakes: [MistakeEntry] {
        guard effectiveSubjectFilter != "all" else { return mistakes }
        return mistakes.filter { $0.subject?.id.uuidString.lowercased() == effectiveSubjectFilter }
    }

    private var focusAverage: Double {
        guard !focusMarkEntries.isEmpty else { return 0 }
        return focusMarkEntries.map(\.percentage).reduce(0, +) / Double(focusMarkEntries.count)
    }

    private var focusBestEntry: MarkEntry? {
        focusMarkEntries.max { $0.percentage < $1.percentage }
    }

    private var focusLowestEntry: MarkEntry? {
        focusMarkEntries.min { $0.percentage < $1.percentage }
    }

    private var focusLatestEntry: MarkEntry? {
        focusMarkEntries.first
    }

    private var focusImprovementFromPrevious: Double? {
        guard focusMarkEntries.count > 1 else { return nil }
        return focusMarkEntries[0].percentage - focusMarkEntries[1].percentage
    }

    private var focusMistakeMarksLost: Double {
        focusMistakes.compactMap(\.marksLost).reduce(0, +)
    }

    private var latestWidgetDetail: String {
        guard let focusLatestEntry else {
            return "Your newest paper in this view will appear here."
        }

        if let focusImprovementFromPrevious {
            let direction = focusImprovementFromPrevious >= 0 ? "up" : "down"
            return "\(focusLatestEntry.paperName) is \(direction) \(abs(focusImprovementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pts from the previous paper."
        }

        return "\(focusLatestEntry.paperName) is the first paper in this view."
    }

    private var mistakeWidgetDetail: String {
        guard !focusMistakes.isEmpty else {
            return "No linked mistakes are tagged to this view yet."
        }

        return "\(focusMistakes.count) review item\(focusMistakes.count == 1 ? "" : "s") connected to \(selectedSubject?.name ?? "your dashboard")."
    }

    private var focusWidgets: [DashboardWidgetMetric] {
        [
            DashboardWidgetMetric(
                title: "Average Score",
                value: focusMarkEntries.isEmpty ? "--" : "\(focusAverage.formatted(.number.precision(.fractionLength(0))))%",
                detail: focusMarkEntries.isEmpty
                    ? "Add a paper for this filter to calculate the mean."
                    : "Across \(focusMarkEntries.count) paper\(focusMarkEntries.count == 1 ? "" : "s") \(focusScopeDescription).",
                systemImage: "gauge.with.dots.needle.50percent",
                tint: StudyTheme.accent
            ),
            DashboardWidgetMetric(
                title: "Best Result",
                value: focusBestEntry.map { "\($0.percentage.formatted(.number.precision(.fractionLength(0))))%" } ?? "--",
                detail: focusBestEntry.map { "\($0.paperName) on \(Formatters.shortDate.string(from: $0.examDate))" }
                    ?? "Your strongest paper will surface here.",
                systemImage: "rosette",
                tint: StudyTheme.warm
            ),
            DashboardWidgetMetric(
                title: "Latest Result",
                value: focusLatestEntry.map { "\($0.percentage.formatted(.number.precision(.fractionLength(0))))%" } ?? "--",
                detail: latestWidgetDetail,
                systemImage: "clock.arrow.circlepath",
                tint: StudyTheme.accentDeep
            ),
            DashboardWidgetMetric(
                title: "Mistake Load",
                value: focusMistakeMarksLost > 0
                    ? "\(focusMistakeMarksLost.formatted(.number.precision(.fractionLength(0)))) marks"
                    : "\(focusMistakes.count) item\(focusMistakes.count == 1 ? "" : "s")",
                detail: mistakeWidgetDetail,
                systemImage: "exclamationmark.bubble",
                tint: StudyTheme.rose
            )
        ]
    }

    private var focusChartDetail: String {
        if let selectedSubject {
            return "Widgets and graph are locked to \(selectedSubject.name), so you can inspect one subject cleanly."
        }

        return "Keep all subjects visible together or tap a chip to isolate one subject at a time."
    }

    private var showSubjectLegend: Bool {
        effectiveSubjectFilter == "all" && Set(filteredTrendPoints.map(\.subjectName)).count > 1
    }

    private var visibleSubjectNames: [String] {
        Array(Set(filteredTrendPoints.map(\.subjectName))).sorted()
    }

    private var visibleSubjectColors: [Color] {
        visibleSubjectNames.enumerated().map { index, _ in
            StudyTheme.chartPalette[index % StudyTheme.chartPalette.count]
        }
    }

    private var chartLatestValue: String {
        guard let latest = focusLatestEntry else { return "--" }
        return "\(latest.percentage.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var chartRangeValue: String {
        guard
            let lowest = focusLowestEntry?.percentage,
            let highest = focusBestEntry?.percentage
        else { return "--" }

        return "\(lowest.formatted(.number.precision(.fractionLength(0))))-\(highest.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var chartVolumeTitle: String {
        showSubjectLegend ? "Subjects" : "Papers"
    }

    private var chartVolumeValue: String {
        showSubjectLegend ? "\(visibleSubjectNames.count)" : "\(focusMarkEntries.count)"
    }

    private var chartSummaryMetrics: [DashboardGraphMetric] {
        [
            DashboardGraphMetric(title: "Latest", value: chartLatestValue, tint: StudyTheme.accent),
            DashboardGraphMetric(title: "Range", value: chartRangeValue, tint: StudyTheme.warm),
            DashboardGraphMetric(title: chartVolumeTitle, value: chartVolumeValue, tint: StudyTheme.accentDeep)
        ]
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
                        subjectFocusSection
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
            .sheet(isPresented: $showingNewTestSheet) {
                TestEditorView(ownerId: ownerId)
            }
            .sheet(isPresented: $showingNewMistakeSheet) {
                MistakeEditorView(ownerId: ownerId)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                StudyBrandMark(size: 62)

                StudyPageHeader(
                    eyebrow: "PAST PAPER TRACKER",
                    title: "Revision snapshot",
                    detail: dashboardMessage
                )
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

            HStack(spacing: 12) {
                Button {
                    showingNewTestSheet = true
                } label: {
                    Label("Log Test", systemImage: "plus.circle.fill")
                }
                .buttonStyle(StudyPrimaryButtonStyle())

                Button {
                    showingNewMistakeSheet = true
                } label: {
                    Label("Add Mistake", systemImage: "exclamationmark.bubble")
                }
                .buttonStyle(StudySecondaryButtonStyle())
            }
        }
        .studyPanel(padding: 24)
    }

    private var subjectFocusSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            StudySectionHeader(
                title: "Subject Lens",
                detail: "Filter the dashboard widgets and graph for each subject."
            )

            subjectFilterSection

            if focusMarkEntries.isEmpty {
                StudyEmptyState(
                    title: "No tests for \(focusLabel)",
                    systemImage: "chart.bar.xaxis",
                    message: "Log a paper for this subject to populate the widgets and trend graph."
                )
                .padding(.top, 8)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(focusWidgets) { widget in
                        StudyDashboardWidget(
                            title: widget.title,
                            value: widget.value,
                            detail: widget.detail,
                            systemImage: widget.systemImage,
                            tint: widget.tint
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    performanceGraphSection
                }
            }
        }
        .studyPanel()
    }

    private var subjectFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    selectedSubjectFilter = "all"
                } label: {
                    StudyFilterChip(title: "All Subjects", isSelected: effectiveSubjectFilter == "all")
                }
                .buttonStyle(.plain)

                ForEach(subjects, id: \.id) { subject in
                    let subjectFilterKey = subject.id.uuidString.lowercased()

                    Button {
                        selectedSubjectFilter = subjectFilterKey
                    } label: {
                        StudyFilterChip(
                            title: subject.name,
                            isSelected: effectiveSubjectFilter == subjectFilterKey
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var multiSubjectTrendChart: some View {
        Chart(filteredTrendPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Percentage", point.percentage),
                series: .value("Subject", point.subjectName)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(by: .value("Subject", point.subjectName))

            PointMark(
                x: .value("Date", point.date),
                y: .value("Percentage", point.percentage)
            )
            .symbolSize(36)
            .foregroundStyle(by: .value("Subject", point.subjectName))
        }
        .chartForegroundStyleScale(
            domain: visibleSubjectNames,
            range: visibleSubjectColors
        )
        .chartLegend(.hidden)
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
            AxisMarks(values: .automatic(desiredCount: min(filteredTrendPoints.count, 4))) {
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(.secondary)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            StudyTheme.accent.opacity(0.06),
                            .primary.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(height: 280)
    }

    private var singleSubjectTrendChart: some View {
        Chart(filteredTrendPoints) { point in
            RuleMark(y: .value("Goal", 70))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .foregroundStyle(StudyTheme.warm.opacity(0.45))
                .annotation(position: .topLeading) {
                    Text("Goal")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(StudyTheme.warm)
                }

            RuleMark(y: .value("Average", focusAverage))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                .foregroundStyle(StudyTheme.accentDeep.opacity(0.55))
                .annotation(position: .topTrailing) {
                    Text("Avg \(focusAverage.formatted(.number.precision(.fractionLength(0))))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(StudyTheme.accentDeep)
                }

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
        .chartForegroundStyleScale(
            domain: visibleSubjectNames,
            range: visibleSubjectColors
        )
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
            AxisMarks(values: .automatic(desiredCount: min(filteredTrendPoints.count, 4))) {
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(.secondary)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            StudyTheme.accent.opacity(0.08),
                            .primary.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(height: 280)
    }

    private var performanceGraphSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Graph")
                    .font(.headline.weight(.semibold))

                Text(focusChartDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(chartSummaryMetrics) { metric in
                    DashboardGraphMetricCard(metric: metric)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Group {
                    if effectiveSubjectFilter == "all" {
                        multiSubjectTrendChart
                    } else {
                        singleSubjectTrendChart
                    }
                }

                if showSubjectLegend {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(zip(visibleSubjectNames, visibleSubjectColors)), id: \.0) { subjectName, color in
                                DashboardLegendChip(title: subjectName, color: color)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(StudyTheme.panelFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
            }

            HStack {
                if let focusLatestEntry {
                    Text("Latest: \(focusLatestEntry.paperName)")
                        .lineLimit(1)
                } else {
                    Text("No latest paper yet")
                }

                Spacer(minLength: 12)

                if let focusImprovementFromPrevious {
                    Text(
                        focusImprovementFromPrevious >= 0
                            ? "Up \(abs(focusImprovementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pts"
                            : "Down \(abs(focusImprovementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pts"
                    )
                } else {
                    Text("Waiting for more data")
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
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
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Subject \(index + 1)")
                                    .font(.caption.weight(.semibold))
                                    .tracking(1.1)
                                    .foregroundStyle(.secondary)

                                Text(average.subjectName)
                                    .font(.headline.weight(.semibold))
                            }

                            Spacer()

                            StudyScorePill(percentage: average.averagePercentage)
                        }

                        StudyProgressBar(
                            progress: average.averagePercentage / 100,
                            tint: StudyTheme.scoreColor(for: average.averagePercentage)
                        )
                    }
                    .studyCard(tint: StudyTheme.scoreColor(for: average.averagePercentage))
                }
            }
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
                LazyVStack(spacing: 14) {
                    ForEach(recentEntries, id: \.id) { entry in
                        NavigationLink {
                            TestDetailView(entry: entry, ownerId: ownerId)
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                StudyTestRowContent(entry: entry, noteLineLimit: 2)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .studyCard(padding: 18, tint: StudyTheme.scoreColor(for: entry.percentage))
                        }
                        .buttonStyle(.plain)
                    }
                }
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
                LazyVStack(spacing: 14) {
                    ForEach(recentMistakes, id: \.id) { mistake in
                        NavigationLink {
                            MistakeDetailView(mistake: mistake, ownerId: ownerId)
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                StudyMistakeRowContent(mistake: mistake)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .studyCard(padding: 18, tint: StudyTheme.rose)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct DashboardWidgetMetric: Identifiable {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var id: String { title }
}

private struct DashboardGraphMetric: Identifiable {
    let title: String
    let value: String
    let tint: Color

    var id: String { title }
}

private struct DashboardGraphMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: DashboardGraphMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

            Text(metric.value)
                .font(.headline.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(metric.tint.opacity(colorScheme == .dark ? 0.14 : 0.10))
        }
    }
}

private struct DashboardLegendChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.62),
            in: Capsule(style: .continuous)
        )
    }
}
