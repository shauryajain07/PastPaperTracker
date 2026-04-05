import PhotosUI
import SwiftData
import SwiftUI

struct GradeBoundarySettingsView: View {
    let ownerId: String

    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme
    @Query private var subjects: [Subject]
    @State private var selectedSubjectID: UUID?
    @State private var manualText = ManualBoundaryTextFields()
    @State private var deepSeekKeyDraft = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var isSavingKey = false
    @State private var sharedCatalogSets: [SharedGradeBoundaryCatalogEntry] = []
    @State private var isLoadingSharedCatalog = false
    @State private var sharedCatalogError: String?
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(ownerId: String) {
        self.ownerId = ownerId
        let deleted = SyncState.pendingDelete.rawValue
        _subjects = Query(
            filter: #Predicate<Subject> { $0.ownerId == ownerId && $0.syncStateRaw != deleted },
            sort: [SortDescriptor(\.name)]
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                StudyPageHeader(
                    eyebrow: "GRADE BOUNDARIES",
                    title: "IB conversion rules",
                    detail: "Set one default boundary set per subject, then import session-based rows like M25 TZ1 so saved test marks can auto-convert into IB grades."
                )
                .studyRevealOnAppear()

                apiKeySection
                    .studyRevealOnAppear(index: 1)

                if subjects.isEmpty {
                    StudyEmptyState(
                        title: "Add a subject first",
                        systemImage: "books.vertical",
                        message: "Grade boundaries are stored per subject, so create your first subject before importing IB tables."
                    )
                    .studyPanel(padding: 28)
                    .studyRevealOnAppear(index: 2)
                } else {
                    subjectSection
                        .studyRevealOnAppear(index: 2)

                    manualBoundariesSection
                        .studyRevealOnAppear(index: 3)

                    importedBoundariesSection
                        .studyRevealOnAppear(index: 4)

                    sharedLibrarySection
                        .studyRevealOnAppear(index: 5)
                }

                if let message = successMessage {
                    statusBanner(message, tint: StudyTheme.accentDeep, fill: StudyTheme.accentSoft.opacity(colorScheme == .dark ? 0.25 : 0.50))
                }

                if let errorMessage {
                    statusBanner(errorMessage, tint: StudyTheme.rose, fill: StudyTheme.rose.opacity(0.10))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .studyScreenBackground()
        .navigationTitle("Grade Boundaries")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await initializeStateIfNeeded()
        }
        .onChange(of: subjects.map(\.id)) { _, _ in
            syncSelectionIfNeeded()
        }
        .onChange(of: selectedSubjectID) { _, _ in
            syncManualDraft()
        }
        .task(id: selectedSubjectID) {
            await loadSharedCatalog()
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard newValue != nil else { return }
            Task {
                await importSelectedScreenshot()
            }
        }
    }

    private var selectedSubject: Subject? {
        guard let selectedSubjectID else { return subjects.first }
        return subjects.first { $0.id == selectedSubjectID }
    }

    private var selectedSubjectImportedSets: [GradeBoundarySet] {
        selectedSubject?.importedGradeBoundarySets ?? []
    }

    private var selectedSubjectImportedSessionCodes: Set<String> {
        Set(selectedSubjectImportedSets.compactMap(\.normalizedSessionCode))
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudySectionHeader(
                title: "DeepSeek Import",
                detail: "Paste a DeepSeek API key once. The app will OCR screenshots locally, ask DeepSeek to normalize the rows into JSON, then cache the result in your database."
            )

            VStack(alignment: .leading, spacing: 18) {
                StudyInfoRow(
                    title: "Key Status",
                    value: environment.deepSeekAPIKeyStore.hasStoredKey ? "Saved in Keychain" : "Missing"
                )

                StudyFieldBlock(title: "API Key") {
                    SecureField("sk-...", text: $deepSeekKeyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .studyInputField()
                }

                HStack(spacing: 12) {
                    Button(isSavingKey ? "Saving..." : "Save Key") {
                        StudyFeedback.impact(.medium)
                        saveAPIKey()
                    }
                    .buttonStyle(StudyPrimaryButtonStyle())
                    .disabled(isSavingKey || deepSeekKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Clear Key") {
                        StudyFeedback.impact(.light)
                        clearAPIKey()
                    }
                    .buttonStyle(StudySecondaryButtonStyle())
                    .disabled(!environment.deepSeekAPIKeyStore.hasStoredKey && deepSeekKeyDraft.isEmpty)
                }

                Text("Imported screenshots are hashed and stored, so the app can reuse an existing extraction instead of calling DeepSeek again for the same image.")
                    .font(.footnote)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
            }
            .studyPanel(padding: 20)
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudySectionHeader(
                title: "Subject",
                detail: "Choose which subject these boundaries belong to."
            )

            StudyFieldBlock(title: "Selected Subject") {
                Picker("Subject", selection: Binding(
                    get: { selectedSubjectID },
                    set: { selectedSubjectID = $0 }
                )) {
                    ForEach(subjects, id: \.id) { subject in
                        Text(subject.name).tag(Optional(subject.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .studyInputField()
            }
            .studyPanel(padding: 20)
        }
    }

    private var manualBoundariesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudySectionHeader(
                title: "Default Subject Boundaries",
                detail: "Use this as the fallback IB conversion when a paper does not match a specific imported session row."
            )

            VStack(alignment: .leading, spacing: 18) {
                GradeThresholdEditor(textFields: $manualText)

                Text("Enter the percentage thresholds for grades 7 through 1. The app will use these values whenever no imported session like M25 TZ1 matches the test name.")
                    .font(.footnote)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Button("Save Default Boundaries") {
                    StudyFeedback.impact(.medium)
                    saveManualBoundaries()
                }
                .buttonStyle(StudyPrimaryButtonStyle())
                .disabled(selectedSubject == nil)
            }
            .studyPanel(padding: 20)
        }
    }

    private var importedBoundariesSection: some View {
        let uploadLabel = isImporting ? "Importing..." : "Upload Screenshot"

        return VStack(alignment: .leading, spacing: 14) {
            StudySectionHeader(
                title: "Import Session Rows",
                detail: "Upload an IB screenshot and store every session row separately, like M25 TZ1, M25 TZ2, and N25 TZ1."
            )

            VStack(alignment: .leading, spacing: 18) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(uploadLabel, systemImage: "photo.badge.plus")
                }
                .buttonStyle(StudyPrimaryButtonStyle())
                .disabled(selectedSubject == nil || isImporting)

                if let subject = selectedSubject {
                    Text("Choose a screenshot for \(subject.name). The app will store the extracted rows once and then match future tests using the paper session code.")
                        .font(.footnote)
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                }

                if selectedSubjectImportedSets.isEmpty {
                    Text("No imported session rows saved for this subject yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(selectedSubjectImportedSets, id: \.id) { set in
                            GradeBoundarySetCard(set: set) {
                                deleteImportedSet(set)
                            }
                        }
                    }
                }
            }
            .studyPanel(padding: 20)
        }
    }

    private var sharedLibrarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudySectionHeader(
                title: "Shared Library",
                detail: "See session-based boundaries already uploaded for this subject and add the ones you want to your own subject."
            )

            VStack(alignment: .leading, spacing: 18) {
                if isLoadingSharedCatalog {
                    ProgressView("Loading shared boundaries...")
                        .tint(StudyTheme.accentDeep)
                } else if let sharedCatalogError {
                    Text(sharedCatalogError)
                        .font(.subheadline)
                        .foregroundStyle(StudyTheme.rose)
                } else if sharedCatalogSets.isEmpty {
                    Text("No shared session rows are available for this subject yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sharedCatalogSets) { set in
                            SharedGradeBoundaryCatalogCard(
                                set: set,
                                isAdded: selectedSubjectImportedSessionCodes.contains(set.normalizedSessionCode)
                            ) {
                                addSharedSetToSubject(set)
                            }
                        }
                    }
                }
            }
            .studyPanel(padding: 20)
        }
    }

    private func initializeStateIfNeeded() async {
        environment.deepSeekAPIKeyStore.refreshState()
        syncSelectionIfNeeded()
        syncManualDraft()
        await loadSharedCatalog()
    }

    private func syncSelectionIfNeeded() {
        if let selectedSubjectID, subjects.contains(where: { $0.id == selectedSubjectID }) {
            return
        }
        selectedSubjectID = subjects.first?.id
    }

    private func syncManualDraft() {
        guard let subject = selectedSubject else {
            manualText = ManualBoundaryTextFields()
            return
        }

        if let manual = subject.manualGradeBoundarySet {
            manualText = ManualBoundaryTextFields(thresholds: manual.thresholds)
        } else {
            manualText = ManualBoundaryTextFields()
        }
    }

    private func saveAPIKey() {
        errorMessage = nil
        successMessage = nil
        isSavingKey = true

        defer { isSavingKey = false }

        do {
            try environment.deepSeekAPIKeyStore.saveKey(deepSeekKeyDraft)
            deepSeekKeyDraft = ""
            successMessage = "DeepSeek API key saved in Keychain."
            StudyFeedback.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func clearAPIKey() {
        errorMessage = nil
        successMessage = nil

        do {
            try environment.deepSeekAPIKeyStore.clearKey()
            deepSeekKeyDraft = ""
            successMessage = "DeepSeek API key removed."
            StudyFeedback.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func saveManualBoundaries() {
        errorMessage = nil
        successMessage = nil

        guard let subject = selectedSubject else {
            errorMessage = "Choose a subject first."
            return
        }

        do {
            let thresholds = try manualText.thresholds()
            try environment.gradeBoundaryRepository.upsertManualBoundary(
                ownerId: ownerId,
                subject: subject,
                thresholds: thresholds
            )
            successMessage = "Default IB boundaries saved for \(subject.name)."
            StudyFeedback.notification(.success)
            Task {
                await environment.triggerSync()
            }
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func importSelectedScreenshot() async {
        errorMessage = nil
        successMessage = nil

        guard let selectedPhotoItem, let subject = selectedSubject else { return }

        isImporting = true
        defer {
            isImporting = false
            self.selectedPhotoItem = nil
        }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                throw GradeBoundaryImportError.unreadableImage
            }

            let parsed = try await environment.gradeBoundaryImportService.importBoundaries(
                from: data,
                subjectName: subject.name
            )

            let saved = try environment.gradeBoundaryRepository.upsertImportedBoundaries(
                ownerId: ownerId,
                subject: subject,
                imageHash: parsed.imageHash,
                sourceSubjectTitle: parsed.sourceSubjectTitle,
                sourceOCRText: parsed.sourceOCRText,
                rows: parsed.rows
            )

            successMessage = "Saved \(saved.count) session-based boundary set\(saved.count == 1 ? "" : "s") for \(subject.name)."
            StudyFeedback.notification(.success)
            await environment.triggerSync()
            await loadSharedCatalog()
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func loadSharedCatalog() async {
        guard let subject = selectedSubject else {
            sharedCatalogSets = []
            sharedCatalogError = nil
            return
        }

        isLoadingSharedCatalog = true
        sharedCatalogError = nil
        defer { isLoadingSharedCatalog = false }

        do {
            sharedCatalogSets = try await environment.sharedGradeBoundaryCatalogService.fetchSharedSets(for: subject)
        } catch {
            sharedCatalogSets = []
            sharedCatalogError = error.localizedDescription
        }
    }

    private func addSharedSetToSubject(_ sharedSet: SharedGradeBoundaryCatalogEntry) {
        errorMessage = nil
        successMessage = nil

        guard let subject = selectedSubject else {
            errorMessage = "Choose a subject first."
            return
        }

        do {
            _ = try environment.gradeBoundaryRepository.upsertSharedSelection(
                ownerId: ownerId,
                subject: subject,
                sharedSet: sharedSet
            )
            successMessage = "Added \(sharedSet.title) to \(subject.name)."
            StudyFeedback.notification(.success)
            Task {
                await environment.triggerSync()
                await loadSharedCatalog()
            }
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func deleteImportedSet(_ set: GradeBoundarySet) {
        errorMessage = nil
        successMessage = nil

        do {
            try environment.gradeBoundaryRepository.markDeleted(set)
            successMessage = "Removed \(set.title) from this subject."
            StudyFeedback.notification(.success)
            Task {
                await environment.triggerSync()
            }
        } catch {
            errorMessage = error.localizedDescription
            StudyFeedback.notification(.error)
        }
    }

    private func statusBanner(_ message: String, tint: Color, fill: Color) -> some View {
        Text(message)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fill)
            }
    }
}

private struct ManualBoundaryTextFields: Equatable {
    var grade7 = ""
    var grade6 = ""
    var grade5 = ""
    var grade4 = ""
    var grade3 = ""
    var grade2 = ""
    var grade1 = "0"

    init() {}

    init(thresholds: GradeBoundaryThresholds) {
        grade7 = thresholds.grade7.cleanBoundaryString
        grade6 = thresholds.grade6.cleanBoundaryString
        grade5 = thresholds.grade5.cleanBoundaryString
        grade4 = thresholds.grade4.cleanBoundaryString
        grade3 = thresholds.grade3.cleanBoundaryString
        grade2 = thresholds.grade2.cleanBoundaryString
        grade1 = thresholds.grade1.cleanBoundaryString
    }

    func thresholds() throws -> GradeBoundaryThresholds {
        guard
            let boundary7 = Double(grade7),
            let boundary6 = Double(grade6),
            let boundary5 = Double(grade5),
            let boundary4 = Double(grade4),
            let boundary3 = Double(grade3),
            let boundary2 = Double(grade2),
            let boundary1 = Double(grade1)
        else {
            throw ManualBoundaryValidationError.invalidNumber
        }

        let thresholds = GradeBoundaryThresholds(
            grade1: boundary1,
            grade2: boundary2,
            grade3: boundary3,
            grade4: boundary4,
            grade5: boundary5,
            grade6: boundary6,
            grade7: boundary7
        )

        guard thresholds.isStrictlyAscending else {
            throw ManualBoundaryValidationError.invalidOrder
        }

        return thresholds
    }
}

private enum ManualBoundaryValidationError: LocalizedError {
    case invalidNumber
    case invalidOrder

    var errorDescription: String? {
        switch self {
        case .invalidNumber:
            return "Enter numeric minimum marks for every grade from 1 to 7."
        case .invalidOrder:
            return "IB boundaries must rise from grade 1 up to grade 7."
        }
    }
}

private struct GradeThresholdEditor: View {
    @Binding var textFields: ManualBoundaryTextFields

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            thresholdField(title: "Grade 7", text: $textFields.grade7)
            thresholdField(title: "Grade 6", text: $textFields.grade6)
            thresholdField(title: "Grade 5", text: $textFields.grade5)
            thresholdField(title: "Grade 4", text: $textFields.grade4)
            thresholdField(title: "Grade 3", text: $textFields.grade3)
            thresholdField(title: "Grade 2", text: $textFields.grade2)
            thresholdField(title: "Grade 1", text: $textFields.grade1)
        }
    }

    private func thresholdField(title: String, text: Binding<String>) -> some View {
        StudyFieldBlock(title: title) {
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .studyInputField()
        }
    }
}

private struct GradeBoundarySetCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let set: GradeBoundarySet
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(set.title)
                        .font(StudyTypography.sectionTitle())
                        .foregroundStyle(.primary)

                    Text(summary)
                        .font(StudyTypography.caption())
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                }

                Spacer(minLength: 12)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }

            Text(boundarySummary)
                .font(StudyTypography.body())
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                }
        }
    }

    private var summary: String {
        if let sourceSubjectTitle = set.sourceSubjectTitle, !sourceSubjectTitle.isEmpty {
            return "Imported from \(sourceSubjectTitle)"
        }
        return "Session-specific boundary set"
    }

    private var boundarySummary: String {
        let thresholds = set.thresholds
        return "7 \(thresholds.grade7.cleanBoundaryString)  6 \(thresholds.grade6.cleanBoundaryString)  5 \(thresholds.grade5.cleanBoundaryString)  4 \(thresholds.grade4.cleanBoundaryString)  3 \(thresholds.grade3.cleanBoundaryString)  2 \(thresholds.grade2.cleanBoundaryString)  1 \(thresholds.grade1.cleanBoundaryString)"
    }
}

private struct SharedGradeBoundaryCatalogCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let set: SharedGradeBoundaryCatalogEntry
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(set.title)
                        .font(StudyTypography.sectionTitle())
                        .foregroundStyle(.primary)

                    Text(summary)
                        .font(StudyTypography.caption())
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                }

                Spacer(minLength: 12)

                if isAdded {
                    Button("Added") {
                        onAdd()
                    }
                    .buttonStyle(StudySecondaryButtonStyle())
                    .disabled(true)
                } else {
                    Button("Add") {
                        onAdd()
                    }
                    .buttonStyle(StudyPrimaryButtonStyle())
                }
            }

            Text(boundarySummary)
                .font(StudyTypography.body())
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                }
        }
    }

    private var summary: String {
        let sourceTitle = set.sourceSubjectTitle ?? set.subjectTitle
        return "Shared for \(sourceTitle)"
    }

    private var boundarySummary: String {
        let thresholds = set.thresholds
        return "7 \(thresholds.grade7.cleanBoundaryString)  6 \(thresholds.grade6.cleanBoundaryString)  5 \(thresholds.grade5.cleanBoundaryString)  4 \(thresholds.grade4.cleanBoundaryString)  3 \(thresholds.grade3.cleanBoundaryString)  2 \(thresholds.grade2.cleanBoundaryString)  1 \(thresholds.grade1.cleanBoundaryString)"
    }
}

private extension Double {
    var cleanBoundaryString: String {
        if rounded() == self {
            return String(Int(self))
        }
        return formatted(.number.precision(.fractionLength(1)))
    }
}
