import SwiftUI

struct MistakeDetailView: View {
    let mistake: MistakeEntry
    let ownerId: String

    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                notesSection

                if let photoPath = mistake.photoPath {
                    photoSection(photoPath: photoPath)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .studyScreenBackground()
        .navigationTitle(mistake.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            MistakeEditorView(ownerId: ownerId, existingMistake: mistake)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            StudyPageHeader(
                eyebrow: mistake.subject?.name ?? "No subject",
                title: mistake.markEntry?.paperName ?? "Standalone review note",
                detail: "Logged on \(Formatters.shortDate.string(from: mistake.createdAt))"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StudyStatChip(
                    title: "Linked Test",
                    value: mistake.markEntry?.paperName ?? "None",
                    systemImage: "link"
                )
                StudyStatChip(
                    title: "Marks Lost",
                    value: mistake.marksLost.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "--",
                    systemImage: "arrow.down.circle"
                )
            }
        }
        .studyPanel(padding: 24)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Notes",
                detail: "Keep the explanation precise enough to review later."
            )

            Text(mistake.note)
                .frame(maxWidth: .infinity, alignment: .leading)
                .studyPanel(padding: 20)
        }
    }

    private func photoSection(photoPath: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader(
                title: "Photo",
                detail: "The original question or working stays attached to this mistake."
            )

            AttachmentThumbnailView(
                relativePath: photoPath,
                size: CGSize(width: 240, height: 240)
            )
                .frame(maxWidth: .infinity, alignment: .leading)
                .studyPanel(padding: 20)
        }
    }
}
