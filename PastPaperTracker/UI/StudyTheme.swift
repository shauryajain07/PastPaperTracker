import SwiftUI
import UIKit

enum StudyTheme {
    static let accent = Color.dynamic(light: 0x7CC56C, dark: 0x90D67B)
    static let accentDeep = Color.dynamic(light: 0x2D6D34, dark: 0x65B86F)
    static let accentSoft = Color.dynamic(light: 0xE8F4E1, dark: 0x18241B)
    static let sky = Color.dynamic(light: 0x6EA8E8, dark: 0x82B7F2)
    static let warm = Color.dynamic(light: 0xD8AF63, dark: 0xE4BF79)
    static let rose = Color.dynamic(light: 0xD97A7D, dark: 0xE59699)
    static let ink = Color.dynamic(light: 0x171C18, dark: 0xF3F5EF)
    static let chartPalette: [Color] = [accent, sky, warm, rose, accentDeep]

    static func canvasGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color.dynamic(light: 0x171C18, dark: 0x08100D),
                    Color.dynamic(light: 0x171C18, dark: 0x0D1713),
                    Color.dynamic(light: 0x171C18, dark: 0x13211B)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.dynamic(light: 0xFBFBF6, dark: 0x0E120F),
                Color.dynamic(light: 0xF1F6EF, dark: 0x111713),
                Color.dynamic(light: 0xEEF1EA, dark: 0x161C17)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func surfacePrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.dynamic(light: 0xFFFFFF, dark: 0x171C18)
            : Color.dynamic(light: 0xFFFFFF, dark: 0x171C18)
    }

    static func surfaceSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.dynamic(light: 0xFFFFFF, dark: 0x1C241E)
            : Color.dynamic(light: 0xF3F5EF, dark: 0x1C241E)
    }

    static func surfaceTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.dynamic(light: 0xFFFFFF, dark: 0x212B24)
            : Color.dynamic(light: 0xECEFE7, dark: 0x212B24)
    }

    static func heroFill(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    accentSoft.opacity(0.22),
                    surfaceSecondary(for: scheme),
                    surfacePrimary(for: scheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                accentSoft.opacity(0.85),
                Color.dynamic(light: 0xF7F8F2, dark: 0x0F1712),
                Color.dynamic(light: 0xFFFFFF, dark: 0x0F1712)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func panelBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .white.opacity(0.06)
            : Color.dynamic(light: 0xE2E6DD, dark: 0x2A332D)
    }

    static func chromeBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .white.opacity(0.08)
            : .white.opacity(0.9)
    }

    static func shadow(for scheme: ColorScheme, tint: Color = .black) -> Color {
        scheme == .dark
            ? tint.opacity(0.18)
            : tint.opacity(0.06)
    }

    static func mutedText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.dynamic(light: 0x000000, dark: 0x93A097)
            : Color.dynamic(light: 0x627066, dark: 0x93A097)
    }

    static func tertiaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .white.opacity(0.56)
            : Color.dynamic(light: 0x899286, dark: 0x7D887F)
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

enum StudyMotion {
    static let quick = Animation.easeOut(duration: 0.14)
    static let spring = Animation.smooth(duration: 0.24)
    static let settle = Animation.smooth(duration: 0.24)
    static let standard = Animation.smooth(duration: 0.28)
    static let expressive = Animation.smooth(duration: 0.26)
    static let gentle = Animation.easeInOut(duration: 0.24)
    static let press = Animation.smooth(duration: 0.16)
    static let ambient = Animation.easeInOut(duration: 16).repeatForever(autoreverses: true)
    static let pulse = Animation.easeInOut(duration: 4.6).repeatForever(autoreverses: true)

    static func reveal(delay: Double = 0) -> Animation {
        gentle.delay(delay)
    }

    static func drift(duration: Double = 14) -> Animation {
        .easeInOut(duration: duration).repeatForever(autoreverses: true)
    }
}

@MainActor
enum StudyFeedback {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        intensity: CGFloat = 1
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        impact(style, intensity: 1)
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func success() {
        notification(.success)
    }

    static func warning() {
        notification(.warning)
    }

    static func error() {
        notification(.error)
    }
}

enum StudyRadius {
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 26
    static let xl: CGFloat = 32
}

enum StudySpacing {
    static let xxs: CGFloat = 6
    static let xs: CGFloat = 10
    static let sm: CGFloat = 14
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum StudyTypography {
    static func largeDisplay() -> Font {
        .custom("Mulish-ExtraBold", size: 34, relativeTo: .largeTitle)
    }

    static func display() -> Font {
        .custom("Mulish-Bold", size: 28, relativeTo: .title)
    }

    static func title() -> Font {
        .custom("Mulish-Bold", size: 22, relativeTo: .title2)
    }

    static func sectionTitle() -> Font {
        .custom("Mulish-SemiBold", size: 18, relativeTo: .title3)
    }

    static func body() -> Font {
        .custom("Mulish-Regular", size: 16, relativeTo: .body)
    }

    static func bodyMedium() -> Font {
        .custom("Mulish-Medium", size: 16, relativeTo: .body)
    }

    static func label() -> Font {
        .custom("Mulish-SemiBold", size: 13, relativeTo: .subheadline)
    }

    static func caption() -> Font {
        .custom("Mulish-Medium", size: 12, relativeTo: .caption)
    }

    static func metric() -> Font {
        .custom("Mulish-ExtraBold", size: 30, relativeTo: .title)
    }
}

private struct StudyBackgroundLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            StudyTheme.canvasGradient(for: colorScheme)

            Circle()
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.10 : 0.09))
                .frame(width: 240, height: 240)
                .blur(radius: 84)
                .offset(x: 150, y: -240)

            Circle()
                .fill(StudyTheme.sky.opacity(colorScheme == .dark ? 0.08 : 0.06))
                .frame(width: 220, height: 220)
                .blur(radius: 88)
                .offset(x: -170, y: 320)

            Ellipse()
                .fill(StudyTheme.warm.opacity(colorScheme == .dark ? 0.04 : 0.05))
                .frame(width: 260, height: 180)
                .blur(radius: 80)
                .offset(x: -40, y: -40)
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

private struct StudyRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let delay: Double
    let offset: CGFloat
    let scale: CGFloat
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible || reduceMotion ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : offset)
            .scaleEffect(isVisible || reduceMotion ? 1 : scale)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(reduceMotion ? nil : StudyMotion.reveal(delay: delay)) {
                    isVisible = true
                }
            }
    }
}

private struct StudySelectionGlowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let tint: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isActive ? tint.opacity(colorScheme == .dark ? 0.14 : 0.07) : .clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isActive ? tint.opacity(colorScheme == .dark ? 0.24 : 0.18) : .clear,
                        lineWidth: 1
                    )
            }
            .animation(reduceMotion ? nil : StudyMotion.settle, value: isActive)
    }
}

private struct StudyIdlePulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.02 : 0.985)
            .animation(reduceMotion ? nil : StudyMotion.pulse, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

private struct StudyPulseGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let tint: Color
    let radius: CGFloat
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .shadow(color: tint.opacity(isAnimating ? 0.22 : 0.08), radius: isAnimating ? radius : radius * 0.55)
            .animation(reduceMotion ? nil : StudyMotion.pulse, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

private struct StudyPanelModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                StudyTheme.surfacePrimary(for: colorScheme).opacity(colorScheme == .dark ? 0.94 : 0.94),
                                StudyTheme.surfaceSecondary(for: colorScheme).opacity(colorScheme == .dark ? 0.92 : 0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
                    .shadow(
                        color: StudyTheme.shadow(for: colorScheme),
                        radius: colorScheme == .dark ? 10 : 12,
                        y: colorScheme == .dark ? 4 : 8
                    )
            }
    }
}

private struct StudyInputModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(StudyTypography.body())
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous)
                    .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous)
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
                RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                StudyTheme.surfacePrimary(for: colorScheme).opacity(colorScheme == .dark ? 0.94 : 0.90),
                                StudyTheme.surfaceSecondary(for: colorScheme).opacity(colorScheme == .dark ? 0.92 : 0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                            .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        StudyTheme.panelBorder(for: colorScheme),
                                        tint.opacity(colorScheme == .dark ? 0.14 : 0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: StudyTheme.shadow(for: colorScheme, tint: tint),
                        radius: colorScheme == .dark ? 10 : 14,
                        y: colorScheme == .dark ? 5 : 8
                    )
            }
    }
}

struct StudyGlassGroup<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
    }
}

extension View {
    func studyScreenBackground() -> some View {
        modifier(StudyScreenBackgroundModifier())
    }

    func studyTopFraming(_ inset: CGFloat = 12) -> some View {
        safeAreaPadding(.top, inset)
    }

    func studyPanel(padding: CGFloat = 22) -> some View {
        modifier(StudyPanelModifier(padding: padding))
    }

    func studyInputField() -> some View {
        modifier(StudyInputModifier())
    }

    func studyCard(padding: CGFloat = 18, tint: Color = StudyTheme.accent) -> some View {
        modifier(StudyCardModifier(padding: padding, tint: tint))
    }

    func studyReveal(delay: Double = 0, offset: CGFloat = 12, scale: CGFloat = 0.985) -> some View {
        modifier(StudyRevealModifier(delay: delay, offset: offset, scale: scale))
    }

    func studySelectionGlow(isActive: Bool, tint: Color = StudyTheme.accent, cornerRadius: CGFloat = StudyRadius.md) -> some View {
        modifier(StudySelectionGlowModifier(isActive: isActive, tint: tint, cornerRadius: cornerRadius))
    }

    func studyIdlePulse() -> some View {
        modifier(StudyIdlePulseModifier())
    }

    func studyPulseGlow(tint: Color = StudyTheme.accent, radius: CGFloat = 22) -> some View {
        modifier(StudyPulseGlowModifier(tint: tint, radius: radius))
    }

    func studyRevealOnAppear(index: Int = 0, offset: CGFloat = 18) -> some View {
        studyReveal(delay: min(Double(index) * 0.05, 0.28), offset: offset, scale: 0.985)
    }
}

struct StudySectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(StudyTypography.sectionTitle())
                .foregroundStyle(.primary)

            Text(detail)
                .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
        }
        .studyReveal(delay: 0.02, offset: 8, scale: 0.99)
    }
}

struct StudyBrandMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            StudyTheme.accentSoft.opacity(colorScheme == .dark ? 0.85 : 1),
                            .white.opacity(colorScheme == .dark ? 0.05 : 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(colorScheme == .dark ? 0.08 : 0.9), lineWidth: 1)
                }

            Circle()
                .fill(StudyTheme.accent.opacity(colorScheme == .dark ? 0.34 : 0.22))
                .frame(width: size * 0.78, height: size * 0.78)
                .blur(radius: size * 0.12)

            Circle()
                .stroke(StudyTheme.accent.opacity(colorScheme == .dark ? 0.18 : 0.22), lineWidth: 1.5)
                .frame(width: size * 0.88, height: size * 0.88)

            Image("brand-logo")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.64, height: size * 0.64)
        }
        .overlay {
            Circle()
                .stroke(StudyTheme.accent.opacity(colorScheme == .dark ? 0.16 : 0.22), lineWidth: 1.2)
                .opacity(0.18)
        }
        .shadow(color: StudyTheme.shadow(for: colorScheme, tint: StudyTheme.accent), radius: size * 0.12, y: size * 0.04)
        .accessibilityHidden(true)
    }
}

struct StudyConfirmationHUD: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background {
                    Circle()
                        .fill(StudyTheme.accentDeep)
                }

            Text(title)
                .font(StudyTypography.bodyMedium())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .background {
            RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.lg, style: .continuous)
                        .stroke(StudyTheme.chromeBorder(for: colorScheme), lineWidth: 1)
                }
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.12), radius: 20, y: 12)
        }
    }
}

struct StudyStatChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(StudyTypography.label())
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(StudyTheme.ink)
                    .frame(width: 32, height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(StudyTheme.accent)
                    }
            }

            Text(value)
                .font(.custom("Mulish-Bold", size: 28, relativeTo: .title3))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            Capsule(style: .continuous)
                .fill(StudyTheme.accent.opacity(0.85))
                .frame(width: 38, height: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                .fill(StudyTheme.surfacePrimary(for: colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .fill(StudyTheme.accentSoft.opacity(colorScheme == .dark ? 0.22 : 0.32))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                }
        }
        .studyReveal(delay: 0.05, offset: 10, scale: 0.985)
    }
}

struct StudyScorePill: View {
    let percentage: Double

    var body: some View {
        Text("\(percentage, specifier: "%.0f")%")
            .font(StudyTypography.label())
            .foregroundStyle(StudyTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(StudyTheme.scoreColor(for: percentage))
            }
    }
}

struct StudyMetaChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var systemImage: String? = nil
    var tint: Color = StudyTheme.sky

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(title)
                .lineLimit(1)
        }
        .font(StudyTypography.caption())
        .foregroundStyle(colorScheme == .dark ? tint.opacity(0.96) : tint.opacity(0.92))
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
            let width = max(proxy.size.width * clampedProgress, clampedProgress == 0 ? 0 : 14)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.primary.opacity(0.08))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
                    .animation(StudyMotion.standard, value: width)
            }
        }
        .frame(height: 10)
    }
}

struct StudyEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(StudyTheme.accentSoft.opacity(colorScheme == .dark ? 0.45 : 0.7))
                    .frame(width: 68, height: 68)

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(StudyTheme.accentDeep)
            }
            .studyIdlePulse()

            VStack(spacing: 6) {
                Text(title)
                    .font(StudyTypography.title())
                    .multilineTextAlignment(.center)

                Text(message)
                    .multilineTextAlignment(.center)
                    .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .studyReveal(delay: 0.03, offset: 8, scale: 0.99)
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
                .font(StudyTypography.caption())
                .tracking(1.5)
                .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))

            Text(title)
                .font(StudyTypography.largeDisplay())
                .foregroundStyle(.primary)
                .lineSpacing(1)

            Text(detail)
                .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
        }
        .studyReveal(delay: 0.03, offset: 10, scale: 0.985)
    }
}

struct StudyInfoRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

            Spacer(minLength: 12)

            Text(value)
                .font(StudyTypography.bodyMedium())
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
        }
        .studyReveal(delay: 0.01, offset: 6, scale: 0.99)
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
                .font(StudyTypography.label())
                .foregroundStyle(.primary)

            if let detail {
                Text(detail)
                    .font(StudyTypography.caption())
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
            }

            content
        }
        .studyReveal(delay: 0.04, offset: 10, scale: 0.985)
    }
}

struct StudyToolbarIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 42, height: 42)
            .background {
                Circle()
                    .fill(StudyTheme.surfacePrimary(for: colorScheme).opacity(colorScheme == .dark ? 0.92 : 0.9))
                    .overlay {
                        Circle()
                            .stroke(StudyTheme.chromeBorder(for: colorScheme), lineWidth: 1)
                    }
                    .shadow(color: StudyTheme.shadow(for: colorScheme), radius: 8, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(StudyMotion.press, value: configuration.isPressed)
    }
}

struct StudyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StudyTypography.bodyMedium())
            .foregroundStyle(StudyTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                StudyTheme.accent,
                                StudyTheme.accent.opacity(0.88)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .shadow(color: StudyTheme.accent.opacity(0.14), radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(StudyMotion.press, value: configuration.isPressed)
    }
}

struct StudySecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StudyTypography.bodyMedium())
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                    .fill(StudyTheme.surfaceSecondary(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                            .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(StudyMotion.press, value: configuration.isPressed)
    }
}

struct StudyCardButtonStyle: ButtonStyle {
    let tint: Color

    init(tint: Color = StudyTheme.accent) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(StudyMotion.quick, value: configuration.isPressed)
    }
}

struct StudyFilterChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            Text(title)
                .lineLimit(1)
        }
        .font(StudyTypography.label())
        .foregroundStyle(isSelected ? StudyTheme.ink : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background {
            Capsule(style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [StudyTheme.accent, StudyTheme.accent.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(StudyTheme.surfaceSecondary(for: colorScheme))
                )
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(
                            isSelected ? .clear : StudyTheme.panelBorder(for: colorScheme),
                            lineWidth: 1
                        )
                }
                .overlay {
                    if isSelected {
                        Capsule(style: .continuous)
                            .strokeBorder(StudyTheme.accent.opacity(0.22), lineWidth: 1)
                    }
                }
        }
        .studySelectionGlow(isActive: isSelected, tint: StudyTheme.accent, cornerRadius: 999)
        .animation(StudyMotion.settle, value: isSelected)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(StudyTypography.label())
                        .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                        .lineLimit(1)

                    Text(value)
                        .font(.custom("Mulish-ExtraBold", size: 34, relativeTo: .title))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StudyTheme.ink)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tint)
                    }
            }

            Spacer(minLength: 0)

            Text(detail)
                .font(StudyTypography.body())
                .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                .fill(StudyTheme.surfacePrimary(for: colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.09 : 0.07))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: StudyRadius.md, style: .continuous)
                        .stroke(StudyTheme.panelBorder(for: colorScheme), lineWidth: 1)
                }
        }
        .studyReveal(delay: 0.06, offset: 12, scale: 0.985)
    }
}

struct StudyTestRowContent: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: MarkEntry
    var noteLineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        StudyMetaChip(title: entry.subject?.name ?? "No subject", systemImage: "books.vertical")
                        StudyMetaChip(title: Formatters.shortDate.string(from: entry.examDate), systemImage: "calendar", tint: StudyTheme.warm)
                    }

                    Text(entry.paperName)
                        .font(StudyTypography.sectionTitle())
                        .foregroundStyle(.primary)

                    if !entry.notes.isEmpty {
                        Text(entry.notes)
                            .font(StudyTypography.body())
                            .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                            .lineLimit(noteLineLimit)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 12) {
                    StudyScorePill(percentage: entry.percentage)

                    Text("\(entry.scoredMarks, specifier: "%.1f") / \(entry.totalMarks, specifier: "%.1f")")
                        .font(StudyTypography.caption())
                        .foregroundStyle(StudyTheme.tertiaryText(for: colorScheme))
                }
            }

            StudyProgressBar(
                progress: entry.percentage / 100,
                tint: StudyTheme.scoreColor(for: entry.percentage)
            )
        }
        .studyReveal(delay: 0.05, offset: 12, scale: 0.985)
    }
}

struct StudyMistakeRowContent: View {
    @Environment(\.colorScheme) private var colorScheme

    let mistake: MistakeEntry
    var noteLineLimit = 2

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let photoPath = mistake.photoPath {
                AttachmentThumbnailView(relativePath: photoPath)
            } else {
                RoundedRectangle(cornerRadius: StudyRadius.sm, style: .continuous)
                    .fill(StudyTheme.accentSoft.opacity(colorScheme == .dark ? 0.3 : 0.7))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "scribble.variable")
                            .font(.title3)
                            .foregroundStyle(StudyTheme.accentDeep)
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
                            .font(StudyTypography.sectionTitle())
                            .foregroundStyle(.primary)
                    }

                    Spacer(minLength: 8)

                    if let marksLost = mistake.marksLost {
                        Text("-\(marksLost, specifier: "%.0f")")
                            .font(StudyTypography.caption())
                            .foregroundStyle(StudyTheme.rose)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(StudyTheme.rose.opacity(0.14))
                            }
                    }
                }

                Text(mistake.note)
                    .font(StudyTypography.body())
                    .foregroundStyle(StudyTheme.mutedText(for: colorScheme))
                    .lineLimit(noteLineLimit)
            }
        }
        .studyReveal(delay: 0.05, offset: 12, scale: 0.985)
    }
}

private extension Color {
    static func dynamic(light: UInt, dark: UInt, opacity: Double = 1) -> Color {
        Color(
            uiColor: UIColor { trait in
                UIColor(
                    hex: trait.userInterfaceStyle == .dark ? dark : light,
                    alpha: opacity
                )
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt, alpha: Double = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
