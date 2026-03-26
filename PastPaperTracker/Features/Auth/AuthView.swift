import SwiftUI

struct AuthView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        case reset = "Reset Password"

        var id: String { rawValue }
    }

    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        StudyBrandMark(size: 110)

                        Text("PAST PAPER TRACKER")
                            .font(.caption.weight(.semibold))
                            .tracking(1.4)
                            .foregroundStyle(StudyTheme.mutedText(for: colorScheme))

                        Text("Track every paper with a calmer workflow.")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Sign in to sync across devices, or stay local while you set the app up.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .studyInputField()

                            if mode != .reset {
                                SecureField("Password", text: $password)
                                    .studyInputField()
                            }
                        }

                        Button {
                            Task {
                                await submit()
                            }
                        } label: {
                            Text(isWorking ? "Working..." : actionLabel)
                        }
                        .buttonStyle(StudyPrimaryButtonStyle())
                        .disabled(isWorking || email.isEmpty || (mode != .reset && password.isEmpty))

                        if let message = sessionStore.lastErrorMessage {
                            Text(message)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(message.localizedCaseInsensitiveContains("sent") ? StudyTheme.accent : StudyTheme.rose)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(
                                            (message.localizedCaseInsensitiveContains("sent")
                                                ? StudyTheme.accent
                                                : StudyTheme.rose
                                            ).opacity(0.10)
                                        )
                                }
                        }
                    }
                    .studyPanel(padding: 24)

                    if !environment.authService.isConfigured {
                        VStack(alignment: .leading, spacing: 14) {
                            StudySectionHeader(
                                title: "Local setup",
                                detail: "Supabase is not configured yet, so cloud sync and email auth stay disabled until you add `SupabaseConfig.plist`."
                            )

                            Button("Continue Offline") {
                                environment.continueOffline()
                            }
                            .buttonStyle(StudySecondaryButtonStyle())
                        }
                        .studyPanel(padding: 24)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .studyScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var actionLabel: String {
        switch mode {
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        case .reset: "Send Reset Link"
        }
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }

        switch mode {
        case .signIn:
            await environment.signIn(email: email, password: password)
        case .signUp:
            await environment.signUp(email: email, password: password)
        case .reset:
            await environment.resetPassword(email: email)
        }
    }
}
