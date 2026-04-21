import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    private let ownerId: String
    @Environment(\.colorScheme) private var colorScheme
    @Query private var subjects: [Subject]
    @Query private var markEntries: [MarkEntry]
    @Query private var mistakes: [MistakeEntry]
    @AppStorage("dashboard.selectedSubjectFilter") private var selectedSubjectFilter = "all"
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

    private var focusTrendPointsChronological: [TrendPoint] {
        filteredTrendPoints.sorted { $0.date < $1.date }
    }

    private var focusRollingTrendPoints: [DashboardRollingPoint] {
        rollingAveragePoints(from: focusTrendPointsChronological)
    }

    private var subjectAverages: [SubjectAverage] {
        AnalyticsCalculator.subjectAverages(from: markEntries)
    }

    private var ibGradePoints: [IBGradePoint] {
        AnalyticsCalculator.ibGradePoints(from: markEntries)
    }

    private var overallAverage: Double {
        guard !markEntries.isEmpty else { return 0 }
        return markEntries.map(\.percentage).reduce(0, +) / Double(markEntries.count)
    }

    private var overallIBAverage: Double? {
        guard !ibGradePoints.isEmpty else { return nil }
        return ibGradePoints.map { Double($0.grade) }.reduce(0, +) / Double(ibGradePoints.count)
    }

    private var overallIBHighGradeCount: Int {
        ibGradePoints.filter { $0.grade >= 6 }.count
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
            return "Average performance is \(overallAverage.formatted(.number.precision(.fractionLength(0))))%, and your latest paper is \(deltaNarrative(improvementFromPrevious)) from the previous one."
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

    private var focusIBGradePoints: [IBGradePoint] {
        guard effectiveSubjectFilter != "all" else { return ibGradePoints }
        return ibGradePoints.filter { $0.subjectFilterKey == effectiveSubjectFilter }
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

    private var focusIBAverage: Double? {
        guard !focusIBGradePoints.isEmpty else { return nil }
        return focusIBGradePoints.map { Double($0.grade) }.reduce(0, +) / Double(focusIBGradePoints.count)
    }

    private var focusLatestIBGradePoint: IBGradePoint? {
        focusIBGradePoints.max { $0.date < $1.date }
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
            return "\(scoreSummary(for: focusLatestEntry)) and \(deltaNarrative(focusImprovementFromPrevious, abbreviated: true)) from the previous paper."
        }

        return "\(scoreSummary(for: focusLatestEntry)) on \(Formatters.shortDate.string(from: focusLatestEntry.examDate))."
    }

    private var mistakeWidgetDetail: String {
        guard !focusMistakes.isEmpty else {
            return "No linked mistakes are tagged to this view yet."
        }

        return "\(focusMistakes.count) review item\(focusMistakes.count == 1 ? "" : "s") connected to \(selectedSubject?.name ?? "your dashboard")."
    }

    private var ibAverageWidgetDetail: String {
        guard !focusIBGradePoints.isEmpty else {
            return "Save IB boundaries for this view to convert raw marks into grades."
        }

        return "\(focusIBGradePoints.count) paper\(focusIBGradePoints.count == 1 ? "" : "s") in this view now resolve to IB grades."
    }

    private var latestIBWidgetDetail: String {
        guard let focusLatestIBGradePoint else {
            return "Your latest IB grade will appear here once boundaries are saved."
        }

        return "\(focusLatestIBGradePoint.paperName) on \(Formatters.shortDate.string(from: focusLatestIBGradePoint.date))."
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
                detail: focusBestEntry.map { "\(scoreSummary(for: $0)) on \(Formatters.shortDate.string(from: $0.examDate))" }
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
                title: "Avg IB Grade",
                value: focusIBAverage.map { "\($0.formatted(.number.precision(.fractionLength(1))))/7" } ?? "--",
                detail: ibAverageWidgetDetail,
                systemImage: "graduationcap",
                tint: StudyTheme.sky
            ),
            DashboardWidgetMetric(
                title: "Latest IB",
                value: focusLatestIBGradePoint.map { "IB \($0.grade)" } ?? "--",
                detail: latestIBWidgetDetail,
                systemImage: "medal.star",
                tint: StudyTheme.warm
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
        if selectedSubject != nil {
            return "Raw papers stay visible as dots, while the line smooths the last few results so the direction is easier to trust."
        }

        return "This view shows your full score flow as one calm trend instead of layering every subject on top of each other."
    }

    private var focusTrendDomain: ClosedRange<Date>? {
        guard
            let first = focusTrendPointsChronological.first?.date,
            let last = focusTrendPointsChronological.last?.date
        else {
            return nil
        }

        if first == last {
            let adjustedLast = Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last
            return first...adjustedLast
        }

        return first...last
    }

    private var rollingAverageValue: String {
        guard let rollingAverage = focusRollingTrendPoints.last?.percentage else { return "--" }
        return "\(rollingAverage.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var bestVisibleValue: String {
        guard let best = focusBestEntry else { return "--" }
        return "\(best.percentage.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var chartLatestValue: String {
        guard let latest = focusLatestEntry else { return "--" }
        return "\(latest.percentage.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var chartVolumeValue: String {
        "\(focusMarkEntries.count)"
    }

    private var subjectComparisonCards: [DashboardSubjectComparison] {
        let groupedPoints = Dictionary(grouping: trendPoints, by: \.subjectName)

        return subjectAverages.enumerated().map { index, average in
            let points = (groupedPoints[average.subjectName] ?? []).sorted { $0.date < $1.date }
            let latest = points.last?.percentage
            let previous = points.dropLast().last?.percentage
            let delta: Double? = {
                guard let latest, let previous else { return nil as Double? }
                return latest - previous
            }()

            return DashboardSubjectComparison(
                subjectName: average.subjectName,
                averagePercentage: average.averagePercentage,
                latestPercentage: latest,
                deltaFromPrevious: delta,
                entryCount: points.count,
                tint: StudyTheme.chartPalette[index % StudyTheme.chartPalette.count],
                points: points
            )
        }
    }

    private var chartSummaryMetrics: [DashboardGraphMetric] {
        [
            DashboardGraphMetric(
                title: "Latest",
                value: chartLatestValue,
                detail: focusLatestEntry.map(scoreSummary(for:)) ?? "Most recent paper in this view",
                tint: StudyTheme.accent
            ),
            DashboardGraphMetric(
                title: "Rolling Avg",
                value: rollingAverageValue,
                detail: "Smoothed across the latest few papers",
                tint: StudyTheme.sky
            ),
            DashboardGraphMetric(
                title: "Best",
                value: bestVisibleValue,
                detail: focusBestEntry.map(scoreSummary(for:)) ?? "Top visible paper",
                tint: StudyTheme.warm
            ),
            DashboardGraphMetric(
                title: "Papers",
                value: chartVolumeValue,
                detail: "Results included in this subject lens",
                tint: StudyTheme.accentDeep
            )
        ]
    }

    private func deltaNarrative(_ delta: Double, abbreviated: Bool = false) -> String {
        let direction = delta >= 0 ? "up" : "down"
        let unit = abbreviated ? "pp" : "percentage points"
        let amount = abs(delta).formatted(.number.precision(.fractionLength(0)))
        return "\(direction) \(amount) \(unit)"
    }

    private func scoreSummary(for entry: MarkEntry) -> String {
        "\(entry.paperName) · \(entry.scoredMarks.formatted(.number.precision(.fractionLength(0...1))))/\(entry.totalMarks.formatted(.number.precision(.fractionLength(0...1))))"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                        .studyRevealOnAppear()

                    if markEntries.isEmpty {
                        StudyEmptyState(
                            title: "No scores yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            message: "Add your first past paper result from the Tests tab to start seeing performance patterns."
                        )
                        .studyPanel(padding: 28)
                    } else {
                        subjectFocusSection
                            .studyRevealOnAppear(index: 1)
                        averagesSection
                            .studyRevealOnAppear(index: 2)
                    }

                    recentTestsSection
                        .studyRevealOnAppear(index: 3)
                    recentMistakesSection
                        .studyRevealOnAppear(index: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .animation(StudyMotion.spring, value: effectiveSubjectFilter)
            }
            .studyScreenBackground()
            .studyTopFraming(18)
            .toolbar(.hidden, for: .navigationBar)
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
                StudyBrandMark(size: 60)

                StudyPageHeader(
                    eyebrow: "PAST PAPER TRACKER",
                    title: "Revision snapshot",
                    detail: dashboardMessage
                )
            }

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Average performance")
                            .font(StudyTypography.body())
                            .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                        Text(markEntries.isEmpty ? "--" : "\(overallAverage.formatted(.number.precision(.fractionLength(0))))%")
                            .font(.custom("Mulish-ExtraBold", size: 44, relativeTo: .largeTitle))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 8) {
                        metricPill(title: "Tests", value: "\(markEntries.count)")
                        metricPill(title: "Mistakes", value: "\(mistakes.count)")
                    }
                }

                StudyProgressBar(
                    progress: overallAverage / 100,
                    tint: StudyTheme.accent
                )

                Text(bestSubjectSummary)
                    .font(StudyTypography.bodyMedium())
                    .foregroundStyle(.primary)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                    .fill(StudyTheme.heroFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.08 : 0.55), lineWidth: 1)
                    }
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
                    title: "IB Avg",
                    value: overallIBAverage.map { "\($0.formatted(.number.precision(.fractionLength(1))))/7" } ?? "--",
                    systemImage: "graduationcap.fill"
                )
                StudyStatChip(
                    title: "Best Subject",
                    value: bestSubjectSummary,
                    systemImage: "sparkles"
                )
                StudyStatChip(
                    title: "IB 6-7",
                    value: ibGradePoints.isEmpty ? "--" : "\(overallIBHighGradeCount)/\(ibGradePoints.count)",
                    systemImage: "medal"
                )
                StudyStatChip(
                    title: "Tests Logged",
                    value: "\(markEntries.count)",
                    systemImage: "doc.text.magnifyingglass"
                )
                StudyStatChip(
                    title: "Marks Lost",
                    value: totalMarksLost > 0 ? "\(totalMarksLost.formatted(.number.precision(.fractionLength(0))))" : "--",
                    systemImage: "arrow.down.circle"
                )
            }

            HStack(spacing: 12) {
                Button {
                    StudyFeedback.impact(.medium)
                    showingNewTestSheet = true
                } label: {
                    Label("Log Test", systemImage: "plus.circle.fill")
                }
                .buttonStyle(StudyPrimaryButtonStyle())

                Button {
                    StudyFeedback.impact(.light)
                    showingNewMistakeSheet = true
                } label: {
                    Label("Add Mistake", systemImage: "exclamationmark.bubble")
                }
                .buttonStyle(StudySecondaryButtonStyle())
            }
        }
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title.uppercased())
                .font(StudyTypography.caption())
                .tracking(1.2)
                .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))

            Text(value)
                .font(StudyTypography.bodyMedium())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(colorScheme == .dark ? 0.08 : 0.6), in: Capsule(style: .continuous))
    }

    private var subjectFocusSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            StudySectionHeader(
                title: "Subject lens",
                detail: "Lock the dashboard to one subject when you want a calmer, cleaner read."
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(focusWidgets) { widget in
                            StudyDashboardWidget(
                                title: widget.title,
                                value: widget.value,
                                detail: widget.detail,
                                systemImage: widget.systemImage,
                                tint: widget.tint
                            )
                            .frame(width: 220)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    performanceGraphSection
                }
            }
        }
        .studyPanel(padding: 22)
    }

    private var subjectFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    guard selectedSubjectFilter != "all" else { return }
                    StudyFeedback.selection()
                    withAnimation(StudyMotion.spring) {
                        selectedSubjectFilter = "all"
                    }
                } label: {
                    StudyFilterChip(title: "All Subjects", isSelected: effectiveSubjectFilter == "all")
                }
                .buttonStyle(.plain)

                ForEach(subjects, id: \.id) { subject in
                    let subjectFilterKey = subject.id.uuidString.lowercased()

                    Button {
                        guard selectedSubjectFilter != subjectFilterKey else { return }
                        StudyFeedback.selection()
                        withAnimation(StudyMotion.spring) {
                            selectedSubjectFilter = subjectFilterKey
                        }
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
            .padding(.trailing, 8)
        }
    }

    private var performanceTrendChart: some View {
        Chart {
            if let domain = focusTrendDomain {
                RectangleMark(
                    xStart: .value("Start", domain.lowerBound),
                    xEnd: .value("End", domain.upperBound),
                    yStart: .value("Target Start", 70),
                    yEnd: .value("Target End", 80)
                )
                .foregroundStyle(StudyTheme.accent.opacity(colorScheme == .dark ? 0.12 : 0.14))
            }

            ForEach(focusTrendPointsChronological) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Percentage", point.percentage)
                )
                .symbolSize(effectiveSubjectFilter == "all" ? 22 : 34)
                .foregroundStyle(
                    effectiveSubjectFilter == "all"
                        ? StudyTheme.sky.opacity(0.45)
                        : StudyTheme.accentDeep.opacity(0.65)
                )
            }

            ForEach(focusRollingTrendPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Percentage", point.percentage)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(StudyTheme.accent)
            }

            if effectiveSubjectFilter != "all" {
                RuleMark(y: .value("Average", focusAverage))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 6]))
                    .foregroundStyle(StudyTheme.warm.opacity(0.72))
                    .annotation(position: .topTrailing) {
                        Text("Avg \(focusAverage.formatted(.number.precision(.fractionLength(0))))%")
                            .font(StudyTypography.caption())
                            .foregroundStyle(StudyTheme.warm)
                    }
            }
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
            AxisMarks(values: .automatic(desiredCount: min(focusTrendPointsChronological.count, 4))) {
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

    private var performanceGraphSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance graph")
                    .font(StudyTypography.sectionTitle())

                Text(focusChartDetail)
                    .font(StudyTypography.body())
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
            }

            LazyVGrid(
                columns: [
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
                performanceTrendChart
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                    .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
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
                            ? "Up \(abs(focusImprovementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pp"
                            : "Down \(abs(focusImprovementFromPrevious).formatted(.number.precision(.fractionLength(0)))) pp"
                    )
                } else {
                    Text("Waiting for more data")
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
        }
    }

    private var averagesSection: some View {
        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Subject radar",
                detail: "A compact compare view keeps the main chart focused and still shows where each subject is heading."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(subjectComparisonCards) { comparison in
                        DashboardSubjectComparisonCard(
                            comparison: comparison,
                            isSelected: selectedSubject?.name == comparison.subjectName
                        )
                        .frame(width: 284)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var recentTestsSection: some View {
        let recentEntries = Array(markEntries.prefix(3))

        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Recent tests",
                detail: "Your latest papers stay close so you can re-open context fast."
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
                        .buttonStyle(StudyCardButtonStyle(tint: StudyTheme.scoreColor(for: entry.percentage)))
                    }
                }
            }
        }
    }

    private var recentMistakesSection: some View {
        let recentMistakes = Array(mistakes.prefix(3))

        return VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Recent mistakes",
                detail: "The errors that still matter most should stay visible and lightweight."
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
                        .buttonStyle(StudyCardButtonStyle(tint: StudyTheme.rose))
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
    let detail: String
    let tint: Color

    var id: String { title }
}

private struct DashboardRollingPoint: Identifiable {
    let date: Date
    let percentage: Double

    var id: Date { date }
}

private struct DashboardSubjectComparison: Identifiable {
    let subjectName: String
    let averagePercentage: Double
    let latestPercentage: Double?
    let deltaFromPrevious: Double?
    let entryCount: Int
    let tint: Color
    let points: [TrendPoint]

    var id: String { subjectName }
}

private struct DashboardGraphMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: DashboardGraphMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.title.uppercased())
                .font(StudyTypography.caption())
                .tracking(1.1)
                .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))

            Text(metric.value)
                .font(StudyTypography.bodyMedium())
                .foregroundStyle(.primary)

            Text(metric.detail)
                .font(StudyTypography.caption())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                .lineLimit(2)
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

private struct DashboardSubjectComparisonCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let comparison: DashboardSubjectComparison
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(comparison.subjectName)
                        .font(StudyTypography.sectionTitle())
                        .foregroundStyle(.primary)

                    Text(comparisonSummary)
                        .font(StudyTypography.caption())
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                }

                Spacer(minLength: 12)

                StudyScorePill(percentage: comparison.averagePercentage)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Trend")
                        .font(StudyTypography.caption())
                        .tracking(1.1)
                        .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))

                    Spacer()

                    Text(latestValue)
                        .font(StudyTypography.bodyMedium())
                        .foregroundStyle(.primary)
                }

                DashboardSparklineChart(
                    points: comparison.points,
                    tint: comparison.tint
                )
                .frame(height: 56)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous)
                    .fill(comparison.tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
            }

            HStack(spacing: 12) {
                metricColumn(title: "Trend", value: trendValue)
                metricColumn(title: "Latest", value: latestValue)
                metricColumn(title: "Papers", value: "\(comparison.entryCount)")
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                .fill(StudyTheme.surfacePrimary(for: colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .fill(comparison.tint.opacity(colorScheme == .dark ? 0.08 : 0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .stroke(
                            isSelected ? comparison.tint.opacity(0.55) : StudyTheme.panelBorder(for: colorScheme),
                            lineWidth: 1
                        )
                }
        )
    }

    private var comparisonSummary: String {
        if isSelected {
            return "Current focus"
        }

        return "\(comparison.entryCount) papers tracked"
    }

    private var latestValue: String {
        guard let latest = comparison.latestPercentage else { return "--" }
        return "\(latest.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var trendValue: String {
        guard let delta = comparison.deltaFromPrevious else { return "New" }
        if delta == 0 { return "Flat" }
        let prefix = delta >= 0 ? "+" : "-"
        return "\(prefix)\(abs(delta).formatted(.number.precision(.fractionLength(0)))) pp"
    }

    private func metricColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(StudyTypography.caption())
                .tracking(1.1)
                .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))

            Text(value)
                .font(StudyTypography.bodyMedium())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardSparklineChart: View {
    @Environment(\.colorScheme) private var colorScheme

    let points: [TrendPoint]
    let tint: Color

    private var domain: ClosedRange<Date>? {
        guard let first = points.first?.date, let last = points.last?.date else { return nil }
        if first == last {
            let end = Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last
            return first...end
        }
        let start = Calendar.current.date(byAdding: .day, value: -2, to: first) ?? first
        let end = Calendar.current.date(byAdding: .day, value: 2, to: last) ?? last
        return start...end
    }

    var body: some View {
        Chart(points) { point in
            RuleMark(y: .value("Mid", 50))
                .foregroundStyle(.clear)

            LineMark(
                x: .value("Date", point.date),
                y: .value("Percentage", point.percentage)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            .foregroundStyle(tint)

            if let latest = points.last, latest.id == point.id {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Percentage", point.percentage)
                )
                .symbolSize(28)
                .foregroundStyle(tint)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: domain ?? Date()...Date())
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(.clear)
        }
    }
}

private func rollingAveragePoints(
    from points: [TrendPoint],
    windowSize: Int = 3
) -> [DashboardRollingPoint] {
    guard !points.isEmpty else { return [] }

    return points.indices.map { index in
        let start = max(0, index - (windowSize - 1))
        let slice = points[start...index]
        let average = slice.map(\.percentage).reduce(0, +) / Double(slice.count)

        return DashboardRollingPoint(
            date: points[index].date,
            percentage: average
        )
    }
}
