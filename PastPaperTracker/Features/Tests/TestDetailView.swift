import SwiftData
import SwiftUI

struct TestDetailView: View {
    let entry: MarkEntry
    let ownerId: String

    @Query private var mistakes: [MistakeEntry]
    @State private var showingEditSheet = false
    @State private var showingNewMistakeSheet = false

    private var gradeMatch: GradeBoundaryMatch? {
        GradeBoundaryResolver.resolvedBoundary(for: entry)
    }

    init(entry: MarkEntry, ownerId: String) {
        self.entry = entry
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        let entryID = entry.id
        _mistakes = Query(
            filter: #Predicate<MistakeEntry> {
                $0.ownerId == ownerId &&
                $0.syncStateRaw != deleted &&
                $0.markEntry?.id == entryID
            },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                    .studyRevealOnAppear()

                if !entry.notes.isEmpty {
                    notesSection
                        .studyRevealOnAppear(index: 1)
                }

                linkedMistakesSection
                    .studyRevealOnAppear(index: 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .studyScreenBackground()
        .navigationTitle(entry.paperName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    StudyFeedback.impact(.light)
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TestEditorView(ownerId: ownerId, existingEntry: entry)
        }
        .sheet(isPresented: $showingNewMistakeSheet) {
            MistakeEditorView(ownerId: ownerId, existingMistake: nil, preselectedMarkEntry: entry)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            StudyPageHeader(
                eyebrow: entry.subject?.name ?? "No subject",
                title: gradeMatch.map { "\(entry.percentage.formatted(.number.precision(.fractionLength(0))))% · IB \($0.grade)" }
                    ?? "\(entry.percentage.formatted(.number.precision(.fractionLength(0))))%",
                detail: "Taken on \(Formatters.shortDate.string(from: entry.examDate))"
            )

            StudyProgressBar(
                progress: entry.percentage / 100,
                tint: StudyTheme.scoreColor(for: entry.percentage)
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StudyStatChip(
                    title: "Score",
                    value: "\(entry.scoredMarks.formatted(.number.precision(.fractionLength(1)))) / \(entry.totalMarks.formatted(.number.precision(.fractionLength(1))))",
                    systemImage: "checkmark.circle"
                )
                if let gradeMatch {
                    StudyStatChip(
                        title: "IB Grade",
                        value: "\(gradeMatch.grade)",
                        systemImage: "graduationcap"
                    )
                }
                StudyStatChip(
                    title: "Linked Mistakes",
                    value: "\(mistakes.count)",
                    systemImage: "link"
                )
                if let gradeMatch {
                    StudyStatChip(
                        title: "Boundary Set",
                        value: gradeMatch.set.kind == .sessionImport ? gradeMatch.set.title : "Default",
                        systemImage: "chart.bar.doc.horizontal"
                    )
                }
            }
        }
        .studyPanel(padding: 24)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Notes",
                detail: "Anything worth remembering about this paper."
            )

            Text(entry.notes)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .studyPanel(padding: 20)
        }
    }

    private var linkedMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Linked Mistakes",
                detail: "Connect the exact errors that came out of this paper."
            )

            VStack(alignment: .leading, spacing: 0) {
                if mistakes.isEmpty {
                    Text("No mistakes linked to this test yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(18)
                } else {
                    ForEach(Array(mistakes.enumerated()), id: \.element.id) { index, mistake in
                        NavigationLink {
                            MistakeDetailView(mistake: mistake, ownerId: ownerId)
                        } label: {
                            StudyMistakeRowContent(mistake: mistake)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(StudyCardButtonStyle(tint: StudyTheme.rose))

                        if index < mistakes.count - 1 {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 18)

                Button {
                    StudyFeedback.impact(.medium)
                    showingNewMistakeSheet = true
                } label: {
                    Text("Add Linked Mistake")
                }
                .buttonStyle(StudySecondaryButtonStyle())
                .padding(18)
            }
            .studyPanel(padding: 0)
        }
    }
}
