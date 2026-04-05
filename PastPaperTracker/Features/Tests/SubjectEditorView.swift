import SwiftUI

struct SubjectEditorView: View {
    let ownerId: String
    let onSaved: (Subject) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var environment: AppEnvironment
    @State private var name = ""
    @State private var sharedSubjects: [SharedSubjectCatalogEntry] = []
    @State private var selectedSharedSubject: SharedSubjectCatalogEntry?
    @State private var isLoadingSharedSubjects = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    StudyPageHeader(
                        eyebrow: "NEW SUBJECT",
                        title: "Create a subject",
                        detail: "Add the subject once, then reuse it across tests and mistakes."
                    )
                    .studyRevealOnAppear()

                    VStack(alignment: .leading, spacing: 14) {
                        StudySectionHeader(
                            title: "Subject",
                            detail: "Pick a shared subject when possible so everyone can reuse the same grade-boundary library."
                        )

                        VStack(alignment: .leading, spacing: 18) {
                            StudyFieldBlock(title: "Name") {
                                TextField("Mathematics", text: $name)
                                    .studyInputField()
                            }

                            if let selectedSharedSubject {
                                Text("Using shared subject: \(selectedSharedSubject.title). Existing shared grade boundaries can be reused automatically.")
                                    .font(.footnote)
                                    .foregroundStyle(StudyTheme.accentDeep)
                            } else if isLoadingSharedSubjects {
                                ProgressView("Loading shared subjects...")
                                    .tint(StudyTheme.accentDeep)
                            } else if !filteredSharedSubjects.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Common Subjects" : "Suggested Matches")
                                        .font(StudyTypography.label())
                                        .foregroundStyle(.primary)

                                    LazyVStack(spacing: 10) {
                                        ForEach(filteredSharedSubjects.prefix(6)) { sharedSubject in
                                            Button {
                                                StudyFeedback.selection()
                                                chooseSharedSubject(sharedSubject)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(sharedSubject.title)
                                                            .font(StudyTypography.bodyMedium())
                                                            .foregroundStyle(.primary)

                                                        Text("Reuse shared boundaries for this subject")
                                                            .font(StudyTypography.caption())
                                                            .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                                                    }

                                                    Spacer(minLength: 12)

                                                    Image(systemName: effectiveSharedSubject?.id == sharedSubject.id ? "checkmark.circle.fill" : "plus.circle")
                                                        .font(.system(size: 18, weight: .semibold))
                                                        .foregroundStyle(
                                                            effectiveSharedSubject?.id == sharedSubject.id
                                                                ? StudyTheme.accentDeep
                                                                : StudyTheme.accent
                                                        )
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(14)
                                                .background {
                                                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                                                        .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                                                        .overlay {
                                                            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                                                                .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                                                        }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            } else if let sharedSubjectHint {
                                Text(sharedSubjectHint)
                                    .font(.footnote)
                                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                            }
                        }
                        .studyPanel(padding: 20)
                    }
                    .studyRevealOnAppear(index: 1)

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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .studyScreenBackground()
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadSharedSubjects()
            }
            .onChange(of: name) { _, newValue in
                guard let selectedSharedSubject else { return }
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.compare(selectedSharedSubject.title, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame {
                    self.selectedSharedSubject = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        StudyFeedback.impact(.light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        StudyFeedback.impact(.medium)
                        save()
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: errorMessage) { oldValue, newValue in
                guard oldValue != newValue, newValue != nil else { return }
                StudyFeedback.notification(.error)
            }
        }
    }

    private var filteredSharedSubjects: [SharedSubjectCatalogEntry] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(sharedSubjects.prefix(8)) }

        let normalized = GradeBoundarySubjectKey.canonicalize(trimmed)
        return sharedSubjects.filter { subject in
            subject.title.localizedCaseInsensitiveContains(trimmed)
                || subject.subjectKey.contains(normalized)
        }
    }

    private var effectiveSharedSubject: SharedSubjectCatalogEntry? {
        if let selectedSharedSubject {
            return selectedSharedSubject
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return sharedSubjects.first { subject in
            subject.title.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                || subject.subjectKey == GradeBoundarySubjectKey.canonicalize(trimmed)
        }
    }

    private var sharedSubjectHint: String? {
        if sharedSubjects.isEmpty {
            return "No shared subject catalog entries are available yet. You can still create your own subject."
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Choose a common subject to reuse shared boundaries, or type your own custom name."
        }

        if effectiveSharedSubject == nil {
            return "No exact shared match yet. Saving will still create a local subject, and future users can reuse it once it syncs."
        }

        return nil
    }

    private func chooseSharedSubject(_ sharedSubject: SharedSubjectCatalogEntry) {
        selectedSharedSubject = sharedSubject
        name = sharedSubject.title
    }

    private func loadSharedSubjects() async {
        isLoadingSharedSubjects = true
        defer { isLoadingSharedSubjects = false }

        do {
            sharedSubjects = try await environment.sharedSubjectCatalogService.fetchSubjects()
        } catch {
            sharedSubjects = []
        }
    }

    private func save() {
        do {
            errorMessage = nil
            isSaving = true

            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let sharedSubject = effectiveSharedSubject
            let catalogKey = sharedSubject?.subjectKey ?? GradeBoundarySubjectKey.canonicalize(trimmedName)
            let subject = try environment.subjectRepository.create(
                ownerId: ownerId,
                name: sharedSubject?.title ?? trimmedName,
                catalogKey: catalogKey
            )

            Task {
                if let sharedSubject {
                    await importSharedBoundariesIfAvailable(for: subject, sharedSubject: sharedSubject)
                }
                await environment.triggerSync()
                await MainActor.run {
                    isSaving = false
                }
            }
            onSaved(subject)
            StudyFeedback.notification(.success)
            dismiss()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func importSharedBoundariesIfAvailable(
        for subject: Subject,
        sharedSubject: SharedSubjectCatalogEntry
    ) async {
        do {
            let sharedSets = try await environment.sharedGradeBoundaryCatalogService.fetchSharedSets(subjectKey: sharedSubject.subjectKey)
            for set in sharedSets {
                _ = try environment.gradeBoundaryRepository.upsertSharedSelection(
                    ownerId: ownerId,
                    subject: subject,
                    sharedSet: set
                )
            }
        } catch {
            return
        }
    }
}
