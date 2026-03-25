import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentSession: AppUserSession?
    @Published var lastErrorMessage: String?

    var currentOwnerID: String? {
        currentSession?.id
    }

    func updateSession(_ session: AppUserSession?) {
        currentSession = session
    }

    func setError(_ message: String?) {
        lastErrorMessage = message
    }
}
