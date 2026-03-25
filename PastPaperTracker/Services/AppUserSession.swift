import Foundation

struct AppUserSession: Equatable, Sendable {
    let id: String
    let email: String?
    let isGuest: Bool
}
