import SwiftUI

struct AttachmentThumbnailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let relativePath: String
    var size: CGSize = CGSize(width: 72, height: 72)

    var body: some View {
        Group {
            if let image = environment.photoStore.image(for: relativePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
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
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }
}
