import SwiftUI

enum StudyTheme {
    static let accent = Color(red: 0.22, green: 0.77, blue: 0.69)
    static let accentDeep = Color(red: 0.08, green: 0.49, blue: 0.46)
    static let warm = Color(red: 0.94, green: 0.80, blue: 0.54)
    static let rose = Color(red: 0.82, green: 0.47, blue: 0.51)
    static let ink = Color(red: 0.08, green: 0.11, blue: 0.17)

    static func canvasGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    StudyTheme.ink,
                    Color(red: 0.11, green: 0.15, blue: 0.24),
                    Color(red: 0.18, green: 0.17, blue: 0.23)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.98, blue: 1.00),
                Color(red: 0.92, green: 0.95, blue: 0.98),
                Color(red: 0.99, green: 0.94, blue: 0.89)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func panelFill(for scheme: ColorScheme) -> AnyShapeStyle {
        if scheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .white.opacity(0.14),
                        .white.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white.opacity(0.94),
                    .white.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    static func subtleFill(for scheme: ColorScheme) -> AnyShapeStyle {
        if scheme == .dark {
            return AnyShapeStyle(.white.opacity(0.06))
        }

        return AnyShapeStyle(.white.opacity(0.58))
    }

    static func panelBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.10) : .white.opacity(0.72)
    }

    static func shadow(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .black.opacity(0.28)
            : Color(red: 0.31, green: 0.38, blue: 0.50).opacity(0.16)
    }

    static func mutedText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .white.opacity(0.72)
            : Color(red: 0.31, green: 0.37, blue: 0.46)
    }

    static func scoreColor(for percentage: Double) -> Color {
        switch percentage {
        case ..<45:
            rose
        case ..<70:
            warm
        default:
            accent
        }
    }
}

private struct StudyBackgroundLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            StudyTheme.canvasGradient(for: colorScheme)

            Circle()
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.24 : 0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 64)
                .offset(x: 180, y: -260)

            Circle()
                .fill(StudyTheme.warm.opacity(colorScheme == .dark ? 0.14 : 0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: -170, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct StudyScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            StudyBackgroundLayer()
            content
        }
        .tint(StudyTheme.accent)
    }
}

private struct StudyPanelModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(StudyTheme.panelFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
                    .shadow(color: StudyTheme.shadow(for: colorScheme), radius: 24, y: 14)
            }
    }
}

private struct StudyInputModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(StudyTheme.subtleFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func studyScreenBackground() -> some View {
        modifier(StudyScreenBackgroundModifier())
    }

    func studyPanel(padding: CGFloat = 20) -> some View {
        modifier(StudyPanelModifier(padding: padding))
    }

    func studyInputField() -> some View {
        modifier(StudyInputModifier())
    }
}

struct StudySectionHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct StudyStatChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(StudyTheme.accent)
                .frame(width: 34, height: 34)
                .background {
                    Circle()
                        .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.18 : 0.14))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Text(value)
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(StudyTheme.subtleFill(for: colorScheme))
        }
    }
}

struct StudyScorePill: View {
    let percentage: Double

    var body: some View {
        Text("\(percentage, specifier: "%.0f")%")
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(StudyTheme.scoreColor(for: percentage))
            .background {
                Capsule(style: .continuous)
                    .fill(StudyTheme.scoreColor(for: percentage).opacity(0.14))
            }
    }
}

struct StudyProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let width = max(proxy.size.width * clampedProgress, clampedProgress == 0 ? 0 : 10)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.primary.opacity(0.08))

                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: width)
            }
        }
        .frame(height: 8)
    }
}

struct StudyEmptyState: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(StudyTheme.accent)

            Text(title)
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)

            Text(message)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StudyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                StudyTheme.accent,
                                StudyTheme.accentDeep
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct StudySecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .fontDesign(.rounded)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(StudyTheme.subtleFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
    }
}

struct StudyFilterChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        StudyTheme.accent,
                                        StudyTheme.accentDeep
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : StudyTheme.subtleFill(for: colorScheme)
                    )
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(
                                isSelected ? .clear : StudyTheme.panelBorder(for: colorScheme),
                                lineWidth: 1
                            )
                    }
            }
    }
}

struct StudyTestRowContent: View {
    let entry: MarkEntry
    var noteLineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.paperName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("\(entry.subject?.name ?? "No subject") • \(Formatters.shortDate.string(from: entry.examDate))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                StudyScorePill(percentage: entry.percentage)
            }

            StudyProgressBar(
                progress: entry.percentage / 100,
                tint: StudyTheme.scoreColor(for: entry.percentage)
            )

            HStack(spacing: 10) {
                Text("\(entry.scoredMarks, specifier: "%.1f") / \(entry.totalMarks, specifier: "%.1f")")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(noteLineLimit)
                }
            }
        }
    }
}

struct StudyMistakeRowContent: View {
    let mistake: MistakeEntry
    var noteLineLimit = 2

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let photoPath = mistake.photoPath {
                AttachmentThumbnailView(relativePath: photoPath)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(StudyTheme.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "scribble.variable")
                            .font(.title3)
                            .foregroundStyle(StudyTheme.accent)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text(mistake.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    if let marksLost = mistake.marksLost {
                        Text("-\(marksLost, specifier: "%.0f")")
                            .font(.footnote.weight(.semibold))
                            .fontDesign(.rounded)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(StudyTheme.rose)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(StudyTheme.rose.opacity(0.14))
                            }
                    }
                }

                Text(mistake.subject?.name ?? "No subject")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(mistake.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(noteLineLimit)
            }
        }
    }
}
