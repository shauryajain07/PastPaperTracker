import SwiftUI

struct SubjectEditorView: View {
    let ownerId: String
    let onSaved: (Subject) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @State private var name = ""
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
                            detail: "Choose the name you want to see across the app."
                        )

                        StudyFieldBlock(title: "Name") {
                            TextField("Mathematics", text: $name)
                                .studyInputField()
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: errorMessage) { oldValue, newValue in
                guard oldValue != newValue, newValue != nil else { return }
                StudyFeedback.notification(.error)
            }
        }
    }

    private func save() {
        do {
            let subject = try environment.subjectRepository.create(ownerId: ownerId, name: name)
            Task {
                await environment.triggerSync()
            }
            onSaved(subject)
            StudyFeedback.notification(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
