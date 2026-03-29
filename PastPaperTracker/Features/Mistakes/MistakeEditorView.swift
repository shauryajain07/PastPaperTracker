import PhotosUI
import SwiftData
import SwiftUI

struct MistakeEditorView: View {
    let ownerId: String
    let existingMistake: MistakeEntry?
    let preselectedMarkEntry: MarkEntry?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @Query private var subjects: [Subject]
    @Query private var markEntries: [MarkEntry]
    @State private var title: String
    @State private var note: String
    @State private var marksLostText: String
    @State private var selectedSubjectID: UUID?
    @State private var selectedMarkEntryID: UUID?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var storedPhotoPath: String?
    @State private var showingNewSubject = false
    @State private var errorMessage: String?
    private let draftPhotoID: UUID

    init(ownerId: String, existingMistake: MistakeEntry? = nil, preselectedMarkEntry: MarkEntry? = nil) {
        self.ownerId = ownerId
        self.existingMistake = existingMistake
        self.preselectedMarkEntry = preselectedMarkEntry
        self.draftPhotoID = existingMistake?.id ?? UUID()
        let deleted = SyncState.pendingDelete.rawValue
        _subjects = Query(
            filter: #Predicate<Subject> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.name)]
        )
        _markEntries = Query(
            filter: #Predicate<MarkEntry> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.examDate, order: .reverse)]
        )
        _title = State(initialValue: existingMistake?.title ?? "")
        _note = State(initialValue: existingMistake?.note ?? "")
        _marksLostText = State(initialValue: existingMistake?.marksLost.map { String($0) } ?? "")
        _selectedSubjectID = State(initialValue: existingMistake?.subject?.id ?? preselectedMarkEntry?.subject?.id)
        _selectedMarkEntryID = State(initialValue: existingMistake?.markEntry?.id ?? preselectedMarkEntry?.id)
        _storedPhotoPath = State(initialValue: existingMistake?.photoPath)
    }

    var body: some View {
        let photoButtonTitle = storedPhotoPath == nil ? "Attach Photo" : "Replace Photo"

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    StudyPageHeader(
                        eyebrow: existingMistake == nil ? "NEW MISTAKE" : "EDIT MISTAKE",
                        title: existingMistake == nil ? "Capture a mistake" : "Refine this review note",
                        detail: "Keep the explanation, evidence, and linked paper together so revision stays actionable."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Mistake",
                            detail: "Write the shortest clear summary of what went wrong."
                        )

                        VStack(alignment: .leading, spacing: 18) {
                            StudyFieldBlock(title: "Title") {
                                TextField("Misread the question", text: $title)
                                    .studyInputField()
                            }

                            StudyFieldBlock(title: "What happened?") {
                                TextField("Describe the mistake and what to watch for next time.", text: $note, axis: .vertical)
                                    .lineLimit(6, reservesSpace: true)
                                    .studyInputField()
                            }

                            StudyFieldBlock(title: "Marks Lost", detail: "Optional") {
                                TextField("4", text: $marksLostText)
                                    .keyboardType(.decimalPad)
                                    .studyInputField()
                            }
                        }
                        .studyPanel(padding: 20)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Links",
                            detail: "Connect this mistake to the subject and, when possible, the test it came from."
                        )

                        VStack(alignment: .leading, spacing: 18) {
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

                            StudyFieldBlock(title: "Linked Test") {
                                Picker("Linked test", selection: $selectedMarkEntryID) {
                                    Text("None").tag(Optional<UUID>.none)
                                    ForEach(availableMarkEntries, id: \.id) { markEntry in
                                        Text(markEntry.paperName).tag(Optional(markEntry.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .studyInputField()
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
                            title: "Photo",
                            detail: "Attach the question or your working when the visual context matters."
                        )

                        VStack(alignment: .leading, spacing: 14) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label(photoButtonTitle, systemImage: "photo.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(StudySecondaryButtonStyle())

                            if let storedPhotoPath {
                                AttachmentThumbnailView(relativePath: storedPhotoPath)

                                Button(role: .destructive) {
                                    environment.photoStore.delete(relativePath: storedPhotoPath)
                                    self.storedPhotoPath = nil
                                } label: {
                                    Text("Remove Photo")
                                        .foregroundStyle(StudyTheme.rose)
                                }
                                .buttonStyle(StudySecondaryButtonStyle())
                            }
                        }
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

                    if existingMistake != nil {
                        Button(role: .destructive) {
                            deleteMistake()
                        } label: {
                            Text("Delete Mistake")
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
            .navigationTitle(existingMistake == nil ? "New Mistake" : "Edit Mistake")
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSubjectID == nil)
                }
            }
            .sheet(isPresented: $showingNewSubject) {
                SubjectEditorView(ownerId: ownerId) { subject in
                    selectedSubjectID = subject.id
                }
            }
            .task(id: selectedPhotoItem) {
                await importSelectedPhoto()
            }
        }
    }

    private var availableMarkEntries: [MarkEntry] {
        guard let selectedSubjectID else { return markEntries }
        return markEntries.filter { $0.subject?.id == selectedSubjectID }
    }

    private func importSelectedPhoto() async {
        guard let selectedPhotoItem else { return }
        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                storedPhotoPath = try environment.photoStore.saveImageData(data, for: draftPhotoID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        guard let selectedSubjectID, let subject = subjects.first(where: { $0.id == selectedSubjectID }) else {
            errorMessage = "Select a subject before saving."
            return
        }

        let linkedTest = selectedMarkEntryID.flatMap { id in
            markEntries.first { $0.id == id }
        }
        let marksLost = Double(marksLostText)

        do {
            if let existingMistake {
                try environment.mistakeRepository.update(
                    existingMistake,
                    subject: subject,
                    markEntry: linkedTest,
                    title: title,
                    marksLost: marksLost,
                    note: note,
                    photoPath: storedPhotoPath
                )
            } else {
                _ = try environment.mistakeRepository.create(
                    ownerId: ownerId,
                    subject: subject,
                    markEntry: linkedTest,
                    title: title,
                    marksLost: marksLost,
                    note: note,
                    photoPath: storedPhotoPath
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

    private func deleteMistake() {
        guard let existingMistake else { return }
        do {
            if let photoPath = existingMistake.photoPath {
                environment.photoStore.delete(relativePath: photoPath)
            }
            try environment.mistakeRepository.markDeleted(existingMistake)
            Task {
                await environment.triggerSync()
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
