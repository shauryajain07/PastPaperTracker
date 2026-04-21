import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class WidgetSnapshotCoordinator {
    private let subjectRepository: SubjectRepository
    private let markRepository: MarkEntryRepository
    private let mistakeRepository: MistakeEntryRepository
    private var refreshTask: Task<Void, Never>?

    init(
        subjectRepository: SubjectRepository,
        markRepository: MarkEntryRepository,
        mistakeRepository: MistakeEntryRepository
    ) {
        self.subjectRepository = subjectRepository
        self.markRepository = markRepository
        self.mistakeRepository = mistakeRepository
    }

    func refreshSnapshot(ownerId: String) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self?.writeSnapshot(ownerId: ownerId)
        }
    }

    func clearSnapshot() {
        refreshTask?.cancel()
        refreshTask = nil
        WidgetSnapshotStore.clear()
        reloadWidgets()
    }

    private func writeSnapshot(ownerId: String) {
        do {
            let subjects = try subjectRepository.fetchActive(ownerId: ownerId)
            let markEntries = try markRepository.fetchActive(ownerId: ownerId)
            let mistakes = try mistakeRepository.fetchActive(ownerId: ownerId)
            WidgetSnapshotStore.save(
                makeSnapshot(subjects: subjects, markEntries: markEntries, mistakes: mistakes)
            )
            reloadWidgets()
        } catch {
            WidgetSnapshotStore.clear()
            reloadWidgets()
        }
    }

    private func makeSnapshot(
        subjects: [Subject],
        markEntries: [MarkEntry],
        mistakes: [MistakeEntry]
    ) -> WidgetDashboardSnapshot {
        let entriesBySubjectID = Dictionary(grouping: markEntries) { $0.subject?.id }
        let mistakesBySubjectID = Dictionary(grouping: mistakes) { $0.subject?.id }
        let latestEntry = markEntries.max { $0.examDate < $1.examDate }
        let overallAverage: Double
        if markEntries.isEmpty {
            overallAverage = 0
        } else {
            overallAverage = markEntries.map(\.percentage).reduce(0, +) / Double(markEntries.count)
        }

        let subjectSummaries = subjects.compactMap { subject -> WidgetSubjectSnapshot? in
            let subjectEntries = entriesBySubjectID[subject.id] ?? []
            guard !subjectEntries.isEmpty else { return nil }

            let sortedEntries = subjectEntries.sorted { $0.examDate < $1.examDate }
            let averagePercentage = subjectEntries.map(\.percentage).reduce(0, +) / Double(subjectEntries.count)
            let latestEntry = sortedEntries.last
            let subjectMistakes = mistakesBySubjectID[subject.id] ?? []

            return WidgetSubjectSnapshot(
                id: subject.id.uuidString.lowercased(),
                name: subject.name,
                averagePercentage: averagePercentage,
                testCount: subjectEntries.count,
                mistakeCount: subjectMistakes.count,
                marksLost: subjectMistakes.compactMap(\.marksLost).reduce(0, +),
                latestPercentage: latestEntry?.percentage,
                latestPaperName: latestEntry?.paperName,
                latestExamDate: latestEntry?.examDate,
                trendPoints: Array(sortedEntries.suffix(8)).map { entry in
                    WidgetTrendPointSnapshot(
                        id: entry.id.uuidString.lowercased(),
                        date: entry.examDate,
                        percentage: entry.percentage,
                        paperName: entry.paperName
                    )
                }
            )
        }
        .sorted { $0.averagePercentage > $1.averagePercentage }

        let focusSubject = subjectSummaries.max { lhs, rhs in
            if lhs.marksLost == rhs.marksLost {
                if lhs.mistakeCount == rhs.mistakeCount {
                    return lhs.averagePercentage < rhs.averagePercentage
                }
                return lhs.mistakeCount < rhs.mistakeCount
            }
            return lhs.marksLost < rhs.marksLost
        }

        return WidgetDashboardSnapshot(
            generatedAt: .now,
            overallAverage: overallAverage,
            testsLogged: markEntries.count,
            mistakesLogged: mistakes.count,
            totalMarksLost: mistakes.compactMap(\.marksLost).reduce(0, +),
            bestSubjectName: subjectSummaries.first?.name,
            bestSubjectAverage: subjectSummaries.first?.averagePercentage,
            latestSubjectID: latestEntry?.subject?.id.uuidString.lowercased(),
            latestSubjectName: latestEntry?.subject?.name,
            latestPaperName: latestEntry?.paperName,
            latestPaperPercentage: latestEntry?.percentage,
            focusSubjectName: focusSubject?.name,
            focusSubjectMarksLost: focusSubject?.marksLost,
            subjectSummaries: subjectSummaries
        )
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
