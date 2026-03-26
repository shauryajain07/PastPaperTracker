import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class WidgetSnapshotCoordinator {
    private let subjectRepository: SubjectRepository
    private let markRepository: MarkEntryRepository
    private let mistakeRepository: MistakeEntryRepository

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

    func clearSnapshot() {
        WidgetSnapshotStore.clear()
        reloadWidgets()
    }

    private func makeSnapshot(
        subjects: [Subject],
        markEntries: [MarkEntry],
        mistakes: [MistakeEntry]
    ) -> WidgetDashboardSnapshot {
        let overallAverage: Double
        if markEntries.isEmpty {
            overallAverage = 0
        } else {
            overallAverage = markEntries.map(\.percentage).reduce(0, +) / Double(markEntries.count)
        }

        let subjectSummaries = subjects.compactMap { subject -> WidgetSubjectSnapshot? in
            let subjectEntries = markEntries.filter { $0.subject?.id == subject.id }
            guard !subjectEntries.isEmpty else { return nil }

            let sortedEntries = subjectEntries.sorted { $0.examDate < $1.examDate }
            let averagePercentage = subjectEntries.map(\.percentage).reduce(0, +) / Double(subjectEntries.count)
            let latestEntry = sortedEntries.last

            return WidgetSubjectSnapshot(
                id: subject.id.uuidString.lowercased(),
                name: subject.name,
                averagePercentage: averagePercentage,
                testCount: subjectEntries.count,
                latestPercentage: latestEntry?.percentage,
                latestPaperName: latestEntry?.paperName,
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

        return WidgetDashboardSnapshot(
            generatedAt: .now,
            overallAverage: overallAverage,
            testsLogged: markEntries.count,
            mistakesLogged: mistakes.count,
            totalMarksLost: mistakes.compactMap(\.marksLost).reduce(0, +),
            bestSubjectName: subjectSummaries.first?.name,
            bestSubjectAverage: subjectSummaries.first?.averagePercentage,
            latestPaperName: markEntries.first?.paperName,
            latestPaperPercentage: markEntries.first?.percentage,
            subjectSummaries: subjectSummaries
        )
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
