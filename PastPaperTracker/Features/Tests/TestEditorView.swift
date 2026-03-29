import SwiftData
import SwiftUI

struct TestEditorView: View {
    let ownerId: String
    let existingEntry: MarkEntry?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @Query private var subjects: [Subject]
    @State private var paperFields: StandardizedPaperNameFields
    @State private var examDate: Date
    @State private var scoredMarksText: String
    @State private var totalMarksText: String
    @State private var notes: String
    @State private var selectedSubjectID: UUID?
    @State private var showingNewSubject = false
    @State private var errorMessage: String?

    init(ownerId: String, existingEntry: MarkEntry? = nil) {
        self.ownerId = ownerId
        self.existingEntry = existingEntry
        let deleted = SyncState.pendingDelete.rawValue
        _subjects = Query(
            filter: #Predicate<Subject> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.name)]
        )
        let initialExamDate = existingEntry?.examDate ?? .now
        _examDate = State(initialValue: initialExamDate)
        _paperFields = State(
            initialValue: existingEntry.flatMap { PaperNameFormatter.parse($0.paperName) }
                ?? PaperNameFormatter.defaultFields(for: initialExamDate)
        )
        _scoredMarksText = State(initialValue: existingEntry.map { String($0.scoredMarks) } ?? "")
        _totalMarksText = State(initialValue: existingEntry.map { String($0.totalMarks) } ?? "")
        _notes = State(initialValue: existingEntry?.notes ?? "")
        _selectedSubjectID = State(initialValue: existingEntry?.subject?.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    StudyPageHeader(
                        eyebrow: existingEntry == nil ? "NEW TEST" : "EDIT TEST",
                        title: existingEntry == nil ? "Log a past paper" : "Refine this result",
                        detail: "Capture the paper details, score, and context in a layout that stays easy to scan later."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Paper",
                            detail: "Standardize the paper name so your history stays consistent."
                        )

                        VStack(alignment: .leading, spacing: 18) {
                            StudyFieldBlock(title: "Year") {
                                TextField(
                                    "2026",
                                    text: Binding(
                                        get: { paperFields.year },
                                        set: { paperFields.year = digitsOnly($0, maxLength: 4) }
                                    )
                                )
                                .keyboardType(.numberPad)
                                .studyInputField()
                            }

                            StudyFieldBlock(title: "Session") {
                                Picker("Session", selection: Binding(
                                    get: { paperFields.session },
                                    set: { paperFields.session = $0 }
                                )) {
                                    ForEach(PastPaperSession.allCases) { session in
                                        Text(session.rawValue).tag(session)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            HStack(alignment: .top, spacing: 12) {
                                StudyFieldBlock(title: "Paper Number") {
                                    TextField(
                                        "12",
                                        text: Binding(
                                            get: { paperFields.paperNumber },
                                            set: { paperFields.paperNumber = digitsOnly($0) }
                                        )
                                    )
                                    .keyboardType(.numberPad)
                                    .studyInputField()
                                }

                                StudyFieldBlock(title: "Timezone") {
                                    TextField(
                                        "1",
                                        text: Binding(
                                            get: { paperFields.timezoneNumber },
                                            set: { paperFields.timezoneNumber = digitsOnly($0) }
                                        )
                                    )
                                    .keyboardType(.numberPad)
                                    .studyInputField()
                                }
                            }

                            StudyFieldBlock(title: "Exam Date") {
                                DatePicker("Exam date", selection: $examDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .studyInputField()
                            }
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Standardized Name",
                            detail: "This is the label that will appear in your result history and linked mistakes."
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text(generatedPaperName)
                                .font(.body.monospaced())
                                .foregroundStyle(canBuildPaperName ? .primary : .secondary)

                            Text("Format: [YEAR]-[M/N]-[Paper Number]-TZ[Timezone number]")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Marks",
                            detail: "Keep both values visible so the percentage remains easy to trust."
                        )

                        HStack(alignment: .top, spacing: 12) {
                            StudyFieldBlock(title: "Scored") {
                                TextField("52", text: $scoredMarksText)
                                    .keyboardType(.decimalPad)
                                    .studyInputField()
                            }

                            StudyFieldBlock(title: "Total") {
                                TextField("75", text: $totalMarksText)
                                    .keyboardType(.decimalPad)
                                    .studyInputField()
                            }
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Subject",
                            detail: "Attach the result to the subject it belongs to."
                        )

                        VStack(alignment: .leading, spacing: 14) {
                            if subjects.isEmpty {
                                Text("Create a subject first to save a test result.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                StudyFieldBlock(title: "Subject") {
                                    Picker("Subject", selection: $selectedSubjectID) {
                                        Text("Select a subject").tag(Optional<UUID>.none)
                                        ForEach(subjects, id: \.id) { subject in
                                            Text(subject.name).tag(Optional(subject.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .studyInputField()
                                }
                            }

                            Button("Add Subject") {
                                showingNewSubject = true
                            }
                            .buttonStyle(StudySecondaryButtonStyle())
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Notes",
                            detail: "Capture anything useful for review, even if it is just one sentence."
                        )

                        TextField("Anything notable about this paper?", text: $notes, axis: .vertical)
                            .lineLimit(4, reservesSpace: true)
                            .studyInputField()
                            .studyPanel(padding: 20)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(StudyTheme.rose)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(StudyTheme.rose.opacity(0.10))
                            }
                    }

                    if existingEntry != nil {
                        Button(role: .destructive) {
                            deleteEntry()
                        } label: {
                            Text("Delete Test")
                                .foregroundStyle(StudyTheme.rose)
                        }
                        .buttonStyle(StudySecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
            .navigationTitle(existingEntry == nil ? "New Test" : "Edit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingNewSubject) {
                SubjectEditorView(ownerId: ownerId) { subject in
                    selectedSubjectID = subject.id
                }
            }
        }
    }

    private var canSave: Bool {
        canBuildPaperName &&
        selectedSubjectID != nil &&
        Double(scoredMarksText) != nil &&
        (Double(totalMarksText) ?? 0) > 0
    }

    private var canBuildPaperName: Bool {
        paperFields.year.count == 4 &&
        !paperFields.paperNumber.isEmpty &&
        !paperFields.timezoneNumber.isEmpty
    }

    private var generatedPaperName: String {
        guard canBuildPaperName else {
            return "Complete all paper fields to generate the standardized name."
        }

        return PaperNameFormatter.build(from: paperFields)
    }

    private func save() {
        guard
            let selectedSubjectID,
            let subject = subjects.first(where: { $0.id == selectedSubjectID }),
            let scoredMarks = Double(scoredMarksText),
            let totalMarks = Double(totalMarksText),
            totalMarks > 0,
            canBuildPaperName
        else {
            errorMessage = "Fill in the standardized paper fields, choose a subject, and enter valid mark values."
            return
        }

        let paperName = PaperNameFormatter.build(from: paperFields)

        do {
            if let existingEntry {
                try environment.markRepository.update(
                    existingEntry,
                    subject: subject,
                    paperName: paperName,
                    examDate: examDate,
                    scoredMarks: scoredMarks,
                    totalMarks: totalMarks,
                    notes: notes
                )
            } else {
                _ = try environment.markRepository.create(
                    ownerId: ownerId,
                    subject: subject,
                    paperName: paperName,
                    examDate: examDate,
                    scoredMarks: scoredMarks,
                    totalMarks: totalMarks,
                    notes: notes
                )
            }

            Task {
                await environment.triggerSync()
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func digitsOnly(_ value: String, maxLength: Int? = nil) -> String {
        let digits = value.filter(\.isNumber)
        guard let maxLength else { return digits }
        return String(digits.prefix(maxLength))
    }

    private func deleteEntry() {
        guard let existingEntry else { return }

        do {
            try environment.markRepository.markDeleted(existingEntry)
            Task {
                await environment.triggerSync()
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
