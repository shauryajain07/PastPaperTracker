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
            Form {
                Section("Subject") {
                    TextField("Mathematics", text: $name)
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("New Subject")
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .studyScreenBackground()
    }

    private func save() {
        do {
            let subject = try environment.subjectRepository.create(ownerId: ownerId, name: name)
            Task {
                await environment.triggerSync()
            }
            onSaved(subject)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
