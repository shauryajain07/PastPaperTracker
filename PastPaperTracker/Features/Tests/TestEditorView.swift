import SwiftData
import SwiftUI

struct TestEditorView: View {
    let ownerId: String
    let existingEntry: MarkEntry?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @Query private var subjects: [Subject]
    @State private var paperName: String
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
        _paperName = State(initialValue: existingEntry?.paperName ?? "")
        _examDate = State(initialValue: existingEntry?.examDate ?? .now)
        _scoredMarksText = State(initialValue: existingEntry.map { String($0.scoredMarks) } ?? "")
        _totalMarksText = State(initialValue: existingEntry.map { String($0.totalMarks) } ?? "")
        _notes = State(initialValue: existingEntry?.notes ?? "")
        _selectedSubjectID = State(initialValue: existingEntry?.subject?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Paper") {
                    TextField("Paper name", text: $paperName)
                    DatePicker("Exam date", selection: $examDate, displayedComponents: .date)
                }

                Section("Marks") {
                    TextField("Scored marks", text: $scoredMarksText)
                        .keyboardType(.decimalPad)
                    TextField("Total marks", text: $totalMarksText)
                        .keyboardType(.decimalPad)
                }

                Section("Subject") {
                    if subjects.isEmpty {
                        Text("Create a subject first to save a test result.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Subject", selection: $selectedSubjectID) {
                            Text("Select a subject").tag(Optional<UUID>.none)
                            ForEach(subjects, id: \.id) { subject in
                                Text(subject.name).tag(Optional(subject.id))
                            }
                        }
                    }

                    Button("Add Subject") {
                        showingNewSubject = true
                    }
                }

                Section("Notes") {
                    TextField("Anything notable about this paper?", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if existingEntry != nil {
                    Section {
                        Button("Delete Test", role: .destructive) {
                            deleteEntry()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
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
        .studyScreenBackground()
    }

    private var canSave: Bool {
        !paperName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSubjectID != nil &&
        Double(scoredMarksText) != nil &&
        (Double(totalMarksText) ?? 0) > 0
    }

    private func save() {
        guard
            let selectedSubjectID,
            let subject = subjects.first(where: { $0.id == selectedSubjectID }),
            let scoredMarks = Double(scoredMarksText),
            let totalMarks = Double(totalMarksText),
            totalMarks > 0
        else {
            errorMessage = "Choose a subject and enter valid mark values."
            return
        }

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
