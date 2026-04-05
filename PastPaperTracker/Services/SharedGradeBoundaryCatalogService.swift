import Foundation
import Supabase

enum SharedGradeBoundaryCatalogError: LocalizedError {
    case backendUnavailable
    case catalogUnavailable

    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            return "Supabase is not configured, so the shared grade-boundary library is unavailable."
        case .catalogUnavailable:
            return "The shared grade-boundary catalog is not installed in Supabase yet. Run the latest schema in supabase/schema.sql."
        }
    }
}

@MainActor
final class SharedGradeBoundaryCatalogService {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func fetchSharedSets(for subject: Subject) async throws -> [SharedGradeBoundaryCatalogEntry] {
        try await fetchSharedSets(subjectKey: subject.sharedCatalogKey)
    }

    func fetchSharedSets(for subjectName: String) async throws -> [SharedGradeBoundaryCatalogEntry] {
        try await fetchSharedSets(subjectKey: GradeBoundarySubjectKey.canonicalize(subjectName))
    }

    func fetchSharedSets(subjectKey: String) async throws -> [SharedGradeBoundaryCatalogEntry] {
        guard let client = authService.client else {
            throw SharedGradeBoundaryCatalogError.backendUnavailable
        }

        guard !subjectKey.isEmpty else { return [] }

        do {
            let rows: [SharedGradeBoundaryCatalogEntry] = try await client
                .from("shared_grade_boundary_sets")
                .select()
                .eq("subject_key", value: subjectKey)
                .order("session_code", ascending: true)
                .execute()
                .value

            return rows.sorted {
                $0.normalizedSessionCode.localizedCaseInsensitiveCompare($1.normalizedSessionCode) == .orderedAscending
            }
        } catch {
            guard Self.isMissingCatalogTableError(error) else { throw error }
            throw SharedGradeBoundaryCatalogError.catalogUnavailable
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

        guard message.contains("shared_grade_boundary_sets") else { return false }

        return message.contains("schema cache")
            || message.contains("could not find the table")
            || message.contains("does not exist")
            || message.contains("relation")
    }
}
