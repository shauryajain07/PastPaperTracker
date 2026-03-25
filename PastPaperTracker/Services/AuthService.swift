import Foundation
import Supabase

@MainActor
protocol AuthService {
    var isConfigured: Bool { get }
    var client: SupabaseClient? { get }
    func restoreSession() async throws -> AppUserSession?
    func signIn(email: String, password: String) async throws -> AppUserSession
    func signUp(email: String, password: String) async throws -> AppUserSession
    func resetPassword(email: String) async throws
    func signOut() async throws
}

enum AuthError: LocalizedError {
    case backendNotConfigured

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "Supabase isn't configured yet. Copy SupabaseConfig.plist.example to SupabaseConfig.plist and add your project values."
        }
    }
}

@MainActor
struct SupabaseAuthService: AuthService {
    let config: SupabaseConfig?
    let client: SupabaseClient?

    init(config: SupabaseConfig?) {
        self.config = config
        if let config {
            self.client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        } else {
            self.client = nil
        }
    }

    var isConfigured: Bool {
        client != nil
    }

    func restoreSession() async throws -> AppUserSession? {
        guard let client else { return nil }
        guard let session = try? await client.auth.session else { return nil }
        return AppUserSession(id: session.user.id.uuidString.lowercased(), email: session.user.email, isGuest: false)
    }

    func signIn(email: String, password: String) async throws -> AppUserSession {
        guard let client else { throw AuthError.backendNotConfigured }
        let session = try await client.auth.signIn(email: email, password: password)
        return AppUserSession(id: session.user.id.uuidString.lowercased(), email: session.user.email, isGuest: false)
    }

    func signUp(email: String, password: String) async throws -> AppUserSession {
        guard let client else { throw AuthError.backendNotConfigured }
        let response = try await client.auth.signUp(email: email, password: password)
        let user = response.user
        return AppUserSession(id: user.id.uuidString.lowercased(), email: user.email, isGuest: false)
    }

    func resetPassword(email: String) async throws {
        guard let client else { throw AuthError.backendNotConfigured }
        try await client.auth.resetPasswordForEmail(email)
    }

    func signOut() async throws {
        guard let client else { return }
        try await client.auth.signOut()
    }
}
