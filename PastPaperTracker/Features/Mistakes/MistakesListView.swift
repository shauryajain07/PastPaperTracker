import SwiftData
import SwiftUI

struct MistakesListView: View {
    let ownerId: String
    @Environment(\.colorScheme) private var colorScheme

    @Query private var mistakes: [MistakeEntry]
    @State private var showingNewMistake = false

    init(ownerId: String) {
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        _mistakes = Query(
            filter: #Predicate<MistakeEntry> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection

                    if mistakes.isEmpty {
                        StudyEmptyState(
                            title: "No mistakes yet",
                            systemImage: "exclamationmark.bubble",
                            message: "Log what went wrong on a paper so you can spot repeat errors faster."
                        )
                        .studyPanel(padding: 28)
                    } else {
                        mistakesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
            .navigationTitle("Mistakes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                    Button {
                        showingNewMistake = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showingNewMistake) {
                MistakeEditorView(ownerId: ownerId)
            }
        }
    }

    private var mistakesWithPhotos: Int {
        mistakes.filter { $0.photoPath != nil }.count
    }

    private var linkedMistakeCount: Int {
        mistakes.filter { $0.markEntry != nil }.count
    }

    private var totalMarksLost: Double {
        mistakes.compactMap(\.marksLost).reduce(0, +)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("MISTAKE LOG")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Text("Review queue")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text(
                    mistakes.isEmpty
                        ? "Capture the misses, attach the question, and make revision more specific."
                        : "Keep recurring slips visible so the same paper pattern does not cost marks twice."
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
                    title: "Logged",
                    value: "\(mistakes.count)",
                    systemImage: "list.bullet.rectangle.portrait"
                )
                StudyStatChip(
                    title: "With Photos",
                    value: "\(mistakesWithPhotos)",
                    systemImage: "photo"
                )
                StudyStatChip(
                    title: "Linked Tests",
                    value: "\(linkedMistakeCount)",
                    systemImage: "link"
                )
                StudyStatChip(
                    title: "Marks Lost",
                    value: totalMarksLost > 0 ? "\(totalMarksLost, specifier: "%.0f")" : "--",
                    systemImage: "arrow.down.circle"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Mistakes",
                detail: "Each entry keeps the context, subject, and image evidence together."
            )

            VStack(spacing: 0) {
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
            .studyPanel(padding: 0)
        }
    }
}
