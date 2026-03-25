import Foundation

final class LocalIdentityStore {
    private let defaults: UserDefaults
    private let guestIDKey = "guest_user_id"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func guestSession() -> AppUserSession {
        if let existing = defaults.string(forKey: guestIDKey) {
            return AppUserSession(id: existing, email: nil, isGuest: true)
        }

        let newID = UUID().uuidString.lowercased()
        defaults.set(newID, forKey: guestIDKey)
        return AppUserSession(id: newID, email: nil, isGuest: true)
    }
}
