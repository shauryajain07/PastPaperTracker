import SwiftData
import SwiftUI

struct MistakesListView: View {
    let ownerId: String

    @Query private var subjects: [Subject]
    @Query private var mistakes: [MistakeEntry]
    @State private var selectedSubjectFilter = "all"
    @State private var showingNewMistake = false

    init(ownerId: String) {
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        _subjects = Query(
            filter: #Predicate<Subject> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.name)]
        )
        _mistakes = Query(
            filter: #Predicate<MistakeEntry> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
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

                    if filteredMistakes.isEmpty {
                        StudyEmptyState(
                            title: mistakes.isEmpty ? "No mistakes yet" : "No mistakes in this lens",
                            systemImage: "exclamationmark.bubble",
                            message: mistakes.isEmpty
                                ? "Log what went wrong on a paper so you can spot repeat errors faster."
                                : "Switch subjects or capture the next mistake to rebuild this review queue."
                        )
                        .studyPanel(padding: 28)
                    } else {
                        mistakesSection
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
            .sheet(isPresented: $showingNewMistake) {
                MistakeEditorView(ownerId: ownerId)
            }
        }
    }

    private var mistakesWithPhotos: Int {
        filteredMistakes.filter { $0.photoPath != nil }.count
    }

    private var linkedMistakeCount: Int {
        filteredMistakes.filter { $0.markEntry != nil }.count
    }

    private var totalMarksLost: Double {
        filteredMistakes.compactMap(\.marksLost).reduce(0, +)
    }

    private var filteredMistakes: [MistakeEntry] {
        guard selectedSubjectFilter != "all" else { return mistakes }
        return mistakes.filter { $0.subject?.id.uuidString.lowercased() == selectedSubjectFilter }
    }

    private var filterLabel: String {
        if selectedSubjectFilter == "all" {
            return "All subjects"
        }

        return subjects.first { $0.id.uuidString.lowercased() == selectedSubjectFilter }?.name ?? "Selected subject"
    }

    private var focusMessage: String {
        filteredMistakes.isEmpty
            ? "Capture the misses, attach the question, and make revision more specific."
            : "Showing \(filteredMistakes.count) review item\(filteredMistakes.count == 1 ? "" : "s") for \(filterLabel.lowercased())."
    }

    private var mostRecentLinkedPaper: String {
        filteredMistakes.compactMap(\.markEntry?.paperName).first ?? "Nothing linked yet"
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            StudyPageHeader(
                eyebrow: "REVIEW QUEUE",
                title: "Mistake review",
                detail: focusMessage
            )

            Button {
                StudyFeedback.impact(.medium)
                showingNewMistake = true
            } label: {
                Label("Capture Mistake", systemImage: "plus.circle.fill")
            }
            .buttonStyle(StudyPrimaryButtonStyle())

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StudyStatChip(
                    title: "Logged",
                    value: "\(filteredMistakes.count)",
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
                    title: "Latest Link",
                    value: mostRecentLinkedPaper,
                    systemImage: "arrow.turn.down.right"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Subject lens",
                detail: "Narrow the queue when you want to revise one subject without the noise from the rest."
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

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Mistakes",
                detail: totalMarksLost > 0
                    ? "This lens has cost roughly \(totalMarksLost.formatted(.number.precision(.fractionLength(0)))) marks so far, so it is worth keeping visible."
                    : "Each entry keeps the context, subject, and evidence together."
            )

            LazyVStack(spacing: 14) {
                ForEach(filteredMistakes, id: \.id) { mistake in
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
