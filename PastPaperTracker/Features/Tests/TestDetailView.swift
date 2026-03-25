import SwiftData
import SwiftUI

struct TestDetailView: View {
    let entry: MarkEntry
    let ownerId: String

    @Query private var mistakes: [MistakeEntry]
    @State private var showingEditSheet = false
    @State private var showingNewMistakeSheet = false

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

                if !entry.notes.isEmpty {
                    notesSection
                }

                linkedMistakesSection
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
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.subject?.name ?? "No subject")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Text("\(entry.percentage, specifier: "%.0f")%")
                    .font(.system(size: 46, weight: .bold, design: .rounded))

                Text("Taken on \(Formatters.shortDate.string(from: entry.examDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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
                StudyStatChip(
                    title: "Linked Mistakes",
                    value: "\(mistakes.count)",
                    systemImage: "link"
                )
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
                        .buttonStyle(.plain)

                        if index < mistakes.count - 1 {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 18)

                Button {
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
