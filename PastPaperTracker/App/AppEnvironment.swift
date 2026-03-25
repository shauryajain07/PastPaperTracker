import Foundation
import SwiftData

@MainActor
final class AppEnvironment: ObservableObject {
    let modelContainer: ModelContainer
    let config: SupabaseConfig?
    let authService: AuthService
    let sessionStore = SessionStore()
    let syncMonitor = SyncMonitor()
    let photoStore = PhotoStore()
    let localIdentityStore = LocalIdentityStore()
    let subjectRepository: SubjectRepository
    let markRepository: MarkEntryRepository
    let mistakeRepository: MistakeEntryRepository
    private(set) lazy var syncEngine = SyncEngine(
        authService: authService,
        subjectRepository: subjectRepository,
        markRepository: markRepository,
        mistakeRepository: mistakeRepository,
        photoStore: photoStore,
        syncMonitor: syncMonitor,
        storageBucket: config?.storageBucket ?? "mistake-photos"
    )
    private var hasBootstrapped = false

    init(modelContainer: ModelContainer = ModelFactory.makeContainer()) {
        self.modelContainer = modelContainer
        let context = modelContainer.mainContext
        self.config = SupabaseConfig.loadFromBundle()
        self.authService = SupabaseAuthService(config: config)
        self.subjectRepository = SubjectRepository(context: context)
        self.markRepository = MarkEntryRepository(context: context)
        self.mistakeRepository = MistakeEntryRepository(context: context)
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        do {
            sessionStore.updateSession(try await authService.restoreSession())
            if let session = sessionStore.currentSession {
                await syncEngine.sync(ownerId: session.id, isGuest: session.isGuest)
            }
        } catch {
            sessionStore.setError(error.localizedDescription)
        }
    }

    func continueOffline() {
        let guestSession = localIdentityStore.guestSession()
        sessionStore.updateSession(guestSession)
        sessionStore.setError(nil)
    }

    func signIn(email: String, password: String) async {
        await authenticate(using: {
            try await authService.signIn(email: email, password: password)
        })
    }

    func signUp(email: String, password: String) async {
        await authenticate(using: {
            try await authService.signUp(email: email, password: password)
        })
    }

    func resetPassword(email: String) async {
        do {
            try await authService.resetPassword(email: email)
            sessionStore.setError("Password reset email sent to \(email).")
        } catch {
            sessionStore.setError(error.localizedDescription)
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
            sessionStore.updateSession(nil)
        } catch {
            sessionStore.setError(error.localizedDescription)
        }
    }

    func triggerSync() async {
        guard let session = sessionStore.currentSession else { return }
        await syncEngine.sync(ownerId: session.id, isGuest: session.isGuest)
    }

    private func authenticate(using action: () async throws -> AppUserSession) async {
        let previousGuestID = sessionStore.currentSession?.isGuest == true ? sessionStore.currentSession?.id : nil

        do {
            let session = try await action()
            if let previousGuestID, previousGuestID != session.id {
                try subjectRepository.migrateOwnership(from: previousGuestID, to: session.id)
                try markRepository.migrateOwnership(from: previousGuestID, to: session.id)
                try mistakeRepository.migrateOwnership(from: previousGuestID, to: session.id)
            }
            sessionStore.updateSession(session)
            sessionStore.setError(nil)
            await triggerSync()
        } catch {
            sessionStore.setError(error.localizedDescription)
        }
    }
}
