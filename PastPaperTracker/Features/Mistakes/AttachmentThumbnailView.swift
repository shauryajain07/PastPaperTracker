import SwiftUI

struct AttachmentThumbnailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let relativePath: String
    var size: CGSize = CGSize(width: 72, height: 72)
    @State private var isPresented = false

    var body: some View {
        Group {
            if let image = environment.photoStore.image(for: relativePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(reduceMotion ? 1 : (isPresented ? 1.03 : 0.96))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(StudyTheme.accent.opacity(0.12))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(StudyTheme.accent)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
        .animation(reduceMotion ? .default : StudyMotion.spring, value: isPresented)
        .onAppear {
            guard !reduceMotion else { return }
            isPresented = true
        }
    }
}
