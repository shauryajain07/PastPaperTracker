import Foundation
import Supabase

enum SharedSubjectCatalogError: LocalizedError {
    case backendUnavailable
    case catalogUnavailable

    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            return "Supabase is not configured, so the shared subject library is unavailable."
        case .catalogUnavailable:
            return "The shared subject catalog is not installed in Supabase yet. Run the latest schema in supabase/schema.sql."
        }
    }
}

@MainActor
final class SharedSubjectCatalogService {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func fetchSubjects() async throws -> [SharedSubjectCatalogEntry] {
        guard let client = authService.client else {
            throw SharedSubjectCatalogError.backendUnavailable
        }

        do {
            let rows: [SharedSubjectCatalogEntry] = try await client
                .from("shared_subjects")
                .select()
                .order("title", ascending: true)
                .execute()
                .value

            return rows.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        } catch {
            guard Self.isMissingCatalogTableError(error) else { throw error }
            throw SharedSubjectCatalogError.catalogUnavailable
        }
    }

    static func isMissingCatalogTableError(_ error: Error) -> Bool {
        let message = [
            error.localizedDescription,
            String(describing: error),
            (error as NSError).localizedFailureReason ?? "",
            (error as NSError).localizedRecoverySuggestion ?? ""
        ]
        .joined(separator: " ")
        .lowercased()

        guard message.contains("shared_subjects") else { return false }

        return message.contains("schema cache")
            || message.contains("could not find the table")
            || message.contains("does not exist")
            || message.contains("relation")
    }
}
