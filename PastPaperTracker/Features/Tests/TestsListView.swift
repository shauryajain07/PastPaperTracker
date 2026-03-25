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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection

                    if !subjects.isEmpty {
                        filterSection
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
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
            .navigationTitle("Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                    Button {
                        showingNewTest = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
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

    private var filterLabel: String {
        if selectedSubjectFilter == "all" {
            return "All subjects"
        }

        return subjects.first { $0.id.uuidString.lowercased() == selectedSubjectFilter }?.name ?? "Selected subject"
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("RESULTS")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Text("Test history")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text(
                    filteredEntries.isEmpty
                        ? "Your completed papers will collect here as a clean running log."
                        : "Showing \(filteredEntries.count) result\(filteredEntries.count == 1 ? "" : "s") for \(filterLabel.lowercased())."
                )
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
                    title: "Subjects",
                    value: "\(subjects.count)",
                    systemImage: "books.vertical"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Filter",
                detail: "Switch views without losing your place in the result stream."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        selectedSubjectFilter = "all"
                    } label: {
                        StudyFilterChip(title: "All Subjects", isSelected: selectedSubjectFilter == "all")
                    }
                    .buttonStyle(.plain)

                    ForEach(subjects, id: \.id) { subject in
                        Button {
                            selectedSubjectFilter = subject.id.uuidString.lowercased()
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
                detail: "Each row keeps the score, timing, and notes visible at a glance."
            )

            VStack(spacing: 0) {
                ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        TestDetailView(entry: entry, ownerId: ownerId)
                    } label: {
                        StudyTestRowContent(entry: entry)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if index < filteredEntries.count - 1 {
                        Divider()
                            .padding(.horizontal, 18)
                    }
                }
            }
            .studyPanel(padding: 0)
        }
    }
}
