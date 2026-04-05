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
    @State private var showingSaveConfirmation = false

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
                    .studyRevealOnAppear()

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
                    .studyRevealOnAppear(index: 1)

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
                                StudyFeedback.impact(.light)
                                showingNewSubject = true
                            }
                            .buttonStyle(StudySecondaryButtonStyle())
                        }
                        .studyPanel(padding: 20)
                    }
                    .studyRevealOnAppear(index: 2)

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
                    .studyRevealOnAppear(index: 3)

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
                            StudyFeedback.impact(.rigid)
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
            .overlay {
                if showingSaveConfirmation {
                    StudyConfirmationHUD(
                        title: existingEntry == nil ? "Paper Saved" : "Paper Updated",
                        systemImage: "checkmark"
                    )
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .animation(StudyMotion.standard, value: showingSaveConfirmation)
            .navigationTitle(existingEntry == nil ? "New Test" : "Edit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        StudyFeedback.impact(.light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        StudyFeedback.impact(.medium)
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: errorMessage) { oldValue, newValue in
                guard oldValue != newValue, newValue != nil else { return }
                StudyFeedback.notification(.error)
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
            showSaveConfirmation()
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
            StudyFeedback.notification(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func showSaveConfirmation() {
        StudyFeedback.notification(.success)
        showingSaveConfirmation = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            dismiss()
        }
    }
}
