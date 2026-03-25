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
            Form {
                Section("Mistake") {
                    TextField("Title", text: $title)
                    TextField("What happened?", text: $note, axis: .vertical)
                        .lineLimit(6, reservesSpace: true)
                    TextField("Marks lost (optional)", text: $marksLostText)
                        .keyboardType(.decimalPad)
                }

                Section("Links") {
                    Picker("Subject", selection: $selectedSubjectID) {
                        Text("Select a subject").tag(Optional<UUID>.none)
                        ForEach(subjects, id: \.id) { subject in
                            Text(subject.name).tag(Optional(subject.id))
                        }
                    }

                    Picker("Linked test", selection: $selectedMarkEntryID) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(availableMarkEntries, id: \.id) { markEntry in
                            Text(markEntry.paperName).tag(Optional(markEntry.id))
                        }
                    }

                    Button("Add Subject") {
                        showingNewSubject = true
                    }
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(photoButtonTitle, systemImage: "photo.badge.plus")
                    }

                    if let storedPhotoPath {
                        AttachmentThumbnailView(relativePath: storedPhotoPath)
                        Button("Remove Photo", role: .destructive) {
                            environment.photoStore.delete(relativePath: storedPhotoPath)
                            self.storedPhotoPath = nil
                        }
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if existingMistake != nil {
                    Section {
                        Button("Delete Mistake", role: .destructive) {
                            deleteMistake()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
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
        .studyScreenBackground()
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
