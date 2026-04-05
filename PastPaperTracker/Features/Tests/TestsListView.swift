import SwiftData
import SwiftUI

struct TestsListView: View {
    let ownerId: String

    @Environment(\.colorScheme) private var colorScheme
    @Query private var subjects: [Subject]
    @Query private var markEntries: [MarkEntry]
    @State private var selectedSubjectFilter = "all"
    @State private var showingNewTest = false

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
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                        .studyRevealOnAppear()

                    if !subjects.isEmpty {
                        filterSection
                            .studyRevealOnAppear(index: 1)
                    }

                    if filteredEntries.isEmpty {
                        StudyEmptyState(
                            title: markEntries.isEmpty ? "No tests yet" : "No tests for this filter",
                            systemImage: "doc.text",
                            message: markEntries.isEmpty
                                ? "Start by logging your first past paper result."
                                : "Try another subject or add the next paper when you complete it."
                        )
                        .studyPanel(padding: 28)
                    } else {
                        resultsSection
                            .studyRevealOnAppear(index: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .animation(StudyMotion.spring, value: selectedSubjectFilter)
            }
            .studyScreenBackground()
            .studyTopFraming(18)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewTest) {
                TestEditorView(ownerId: ownerId)
            }
        }
    }

    private var filteredEntries: [MarkEntry] {
        guard selectedSubjectFilter != "all" else { return markEntries }
        return markEntries.filter { $0.subject?.id.uuidString.lowercased() == selectedSubjectFilter }
    }

    private var filteredAverage: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        return filteredEntries.map(\.percentage).reduce(0, +) / Double(filteredEntries.count)
    }

    private var bestResult: Double {
        filteredEntries.map(\.percentage).max() ?? 0
    }

    private var latestEntry: MarkEntry? {
        filteredEntries.first
    }

    private var improvementFromPrevious: Double? {
        guard filteredEntries.count > 1 else { return nil }
        return filteredEntries[0].percentage - filteredEntries[1].percentage
    }

    private var filterLabel: String {
        if selectedSubjectFilter == "all" {
            return "All subjects"
        }

        return subjects.first { $0.id.uuidString.lowercased() == selectedSubjectFilter }?.name ?? "Selected subject"
    }

    private var heroSummary: String {
        if filteredEntries.isEmpty {
            return "Your completed papers will collect here in one clean, scannable timeline."
        }

        return "Showing \(filteredEntries.count) result\(filteredEntries.count == 1 ? "" : "s") for \(filterLabel.lowercased())."
    }

    private var momentumSummary: String {
        guard let improvementFromPrevious else {
            return "Add another paper to measure your current pace."
        }

        if improvementFromPrevious == 0 {
            return "Performance is holding steady across the last two papers."
        }

        let direction = improvementFromPrevious > 0 ? "up" : "down"
        return "Your latest paper is \(direction) \(abs(improvementFromPrevious).formatted(.number.precision(.fractionLength(0)))) points from the one before it."
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            StudyPageHeader(
                eyebrow: "RESULTS LIBRARY",
                title: "Test history",
                detail: heroSummary
            )

            Button {
                StudyFeedback.impact(.medium)
                showingNewTest = true
            } label: {
                Label("Log New Test", systemImage: "plus.circle.fill")
            }
            .buttonStyle(StudyPrimaryButtonStyle())

            Text(momentumSummary)
                .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StudyStatChip(
                    title: "Visible Tests",
                    value: "\(filteredEntries.count)",
                    systemImage: "text.line.first.and.arrowtriangle.forward"
                )
                StudyStatChip(
                    title: "Average",
                    value: filteredEntries.isEmpty ? "--" : "\(filteredAverage.formatted(.number.precision(.fractionLength(0))))%",
                    systemImage: "chart.bar.xaxis"
                )
                StudyStatChip(
                    title: "Best Result",
                    value: filteredEntries.isEmpty ? "--" : "\(bestResult.formatted(.number.precision(.fractionLength(0))))%",
                    systemImage: "rosette"
                )
                StudyStatChip(
                    title: "Latest",
                    value: latestEntry.map { $0.paperName } ?? "--",
                    systemImage: "clock"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Filter",
                detail: "Switch subjects without losing your place in the result stream."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        guard selectedSubjectFilter != "all" else { return }
                        StudyFeedback.selection()
                        withAnimation(StudyMotion.spring) {
                            selectedSubjectFilter = "all"
                        }
                    } label: {
                        StudyFilterChip(title: "All Subjects", isSelected: selectedSubjectFilter == "all")
                    }
                    .buttonStyle(.plain)

                    ForEach(subjects, id: \.id) { subject in
                        Button {
                            let nextFilter = subject.id.uuidString.lowercased()
                            guard selectedSubjectFilter != nextFilter else { return }
                            StudyFeedback.selection()
                            withAnimation(StudyMotion.spring) {
                                selectedSubjectFilter = nextFilter
                            }
                        } label: {
                            StudyFilterChip(
                                title: subject.name,
                                isSelected: selectedSubjectFilter == subject.id.uuidString.lowercased()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Results",
                detail: "Each card keeps score, date, and context visible at a glance."
            )

            LazyVStack(spacing: 14) {
                ForEach(filteredEntries, id: \.id) { entry in
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
