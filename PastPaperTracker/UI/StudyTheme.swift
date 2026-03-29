import SwiftUI

enum StudyTheme {
    static let accent = Color(red: 0.18, green: 0.48, blue: 0.96)
    static let accentDeep = Color(red: 0.10, green: 0.29, blue: 0.74)
    static let warm = Color(red: 0.95, green: 0.72, blue: 0.35)
    static let rose = Color(red: 0.87, green: 0.35, blue: 0.43)
    static let ink = Color(red: 0.07, green: 0.10, blue: 0.17)
    static let chartPalette: [Color] = [
        accent,
        accentDeep,
        warm,
        rose,
        Color(red: 0.26, green: 0.67, blue: 0.80),
        Color(red: 0.52, green: 0.44, blue: 0.89)
    ]

    static func canvasGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    StudyTheme.ink,
                    Color(red: 0.09, green: 0.14, blue: 0.24),
                    Color(red: 0.14, green: 0.17, blue: 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.98, blue: 1.00),
                Color(red: 0.93, green: 0.95, blue: 0.99),
                Color(red: 0.95, green: 0.96, blue: 0.98)
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
                        accent.opacity(0.08),
                        .white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white.opacity(0.95),
                    accent.opacity(0.06),
                    .white.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    static func subtleFill(for scheme: ColorScheme) -> AnyShapeStyle {
        if scheme == .dark {
            return AnyShapeStyle(.white.opacity(0.08))
        }

        return AnyShapeStyle(.white.opacity(0.72))
    }

    static func panelBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.12) : .white.opacity(0.84)
    }

    static func chromeBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.14) : Color.white.opacity(0.92)
    }

    static func shadow(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .black.opacity(0.28)
            : Color(red: 0.20, green: 0.28, blue: 0.41).opacity(0.12)
    }

    static func mutedText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .white.opacity(0.72)
            : Color(red: 0.34, green: 0.39, blue: 0.49)
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
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 72)
                .offset(x: 190, y: -270)

            Circle()
                .fill(StudyTheme.warm.opacity(colorScheme == .dark ? 0.08 : 0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 64)
                .offset(x: -180, y: 280)

            Circle()
                .fill(StudyTheme.accentDeep.opacity(colorScheme == .dark ? 0.16 : 0.06))
                .frame(width: 240, height: 240)
                .blur(radius: 56)
                .offset(x: -150, y: -180)
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
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(StudyTheme.panelFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
                    .shadow(color: StudyTheme.shadow(for: colorScheme), radius: 24, y: 16)
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
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(StudyTheme.subtleFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
            }
    }
}

private struct StudyCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let padding: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [
                                    .white.opacity(0.11),
                                    tint.opacity(0.08),
                                    .white.opacity(0.05)
                                ]
                                : [
                                    .white.opacity(0.96),
                                    tint.opacity(0.08),
                                    .white.opacity(0.88)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(colorScheme == .dark ? 0.18 : 0.98),
                                        tint.opacity(colorScheme == .dark ? 0.16 : 0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: tint.opacity(colorScheme == .dark ? 0.10 : 0.08), radius: 18, y: 10)
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

    func studyCard(padding: CGFloat = 18, tint: Color = StudyTheme.accent) -> some View {
        modifier(StudyCardModifier(padding: padding, tint: tint))
    }
}

struct StudySectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
        }
    }
}

struct StudyBrandMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: size * 0.92, height: size * 0.92)
                .blur(radius: size * 0.18)

            Image("brand-logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(
                    color: StudyTheme.accent.opacity(colorScheme == .dark ? 0.16 : 0.10),
                    radius: size * 0.14,
                    y: size * 0.04
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct StudyStatChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StudyTheme.accent)
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(colorScheme == .dark ? 0.12 : 0.42), lineWidth: 1)
                            }
                    }
            }

            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Capsule(style: .continuous)
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.92 : 0.74))
                .frame(width: 42, height: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                .white.opacity(0.10),
                                .white.opacity(0.04)
                            ]
                            : [
                                .white.opacity(0.96),
                                StudyTheme.accent.opacity(0.08)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.16 : 0.90),
                                    StudyTheme.accent.opacity(colorScheme == .dark ? 0.14 : 0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
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

struct StudyMetaChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var systemImage: String? = nil
    var tint: Color = StudyTheme.accentDeep

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }

            Text(title)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(colorScheme == .dark ? tint.opacity(0.92) : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            Capsule(style: .continuous)
                .fill(tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
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

struct StudyPageHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct StudyInfoRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
        }
    }
}

struct StudyFieldBlock<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let detail: String?
    let content: Content

    init(
        title: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
            }

            content
        }
    }
}

struct StudyToolbarIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 40, height: 40)
            .background {
                Circle()
                    .fill(StudyTheme.panelFill(for: colorScheme))
                    .overlay {
                        Circle()
                            .stroke(StudyTheme.chromeBorder(for: colorScheme), lineWidth: 1)
                    }
                    .shadow(color: StudyTheme.shadow(for: colorScheme), radius: 10, y: 6)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(StudyTheme.subtleFill(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
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

struct StudyDashboardWidget: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background {
                        Circle()
                            .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.14))
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(colorScheme == .dark ? 0.12 : 0.46), lineWidth: 1)
                            }
                    }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 10) {
                Capsule(style: .continuous)
                    .fill(tint.opacity(colorScheme == .dark ? 0.92 : 0.78))
                    .frame(width: 54, height: 4)

                Text(detail)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                .white.opacity(0.11),
                                tint.opacity(0.08)
                            ]
                            : [
                                .white.opacity(0.95),
                                tint.opacity(0.10)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.18 : 0.96),
                                    tint.opacity(colorScheme == .dark ? 0.18 : 0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: tint.opacity(colorScheme == .dark ? 0.10 : 0.08), radius: 20, y: 10)
        }
    }
}

struct StudyTestRowContent: View {
    let entry: MarkEntry
    var noteLineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StudyMetaChip(title: entry.subject?.name ?? "No subject", systemImage: "books.vertical")
                        StudyMetaChip(title: Formatters.shortDate.string(from: entry.examDate), systemImage: "calendar", tint: StudyTheme.warm)
                    }

                    Text(entry.paperName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if !entry.notes.isEmpty {
                        Text(entry.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(noteLineLimit)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {
                    StudyScorePill(percentage: entry.percentage)

                    Text("\(entry.scoredMarks, specifier: "%.1f") / \(entry.totalMarks, specifier: "%.1f")")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            StudyProgressBar(
                progress: entry.percentage / 100,
                tint: StudyTheme.scoreColor(for: entry.percentage)
            )
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            StudyMetaChip(title: mistake.subject?.name ?? "No subject", systemImage: "books.vertical")

                            if let paperName = mistake.markEntry?.paperName {
                                StudyMetaChip(title: paperName, systemImage: "link", tint: StudyTheme.warm)
                            }
                        }

                        Text(mistake.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }

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

                Text(mistake.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(noteLineLimit)
            }
        }
    }
}
