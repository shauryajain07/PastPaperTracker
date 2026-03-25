import Foundation
import Supabase

@MainActor
final class SyncEngine {
    private let authService: AuthService
    private let subjectRepository: SubjectRepository
    private let markRepository: MarkEntryRepository
    private let mistakeRepository: MistakeEntryRepository
    private let photoStore: PhotoStore
    private let syncMonitor: SyncMonitor
    private let storageBucket: String

    init(
        authService: AuthService,
        subjectRepository: SubjectRepository,
        markRepository: MarkEntryRepository,
        mistakeRepository: MistakeEntryRepository,
        photoStore: PhotoStore,
        syncMonitor: SyncMonitor,
        storageBucket: String
    ) {
        self.authService = authService
        self.subjectRepository = subjectRepository
        self.markRepository = markRepository
        self.mistakeRepository = mistakeRepository
        self.photoStore = photoStore
        self.syncMonitor = syncMonitor
        self.storageBucket = storageBucket
    }

    func sync(ownerId: String, isGuest: Bool) async {
        guard !isGuest, let client = authService.client else { return }

        syncMonitor.isSyncing = true
        syncMonitor.lastErrorMessage = nil
        defer { syncMonitor.isSyncing = false }

        do {
            try await pullRemoteData(ownerId: ownerId, client: client)
            try await pushPendingDeletes(ownerId: ownerId, client: client)
            try await pushPendingUploads(ownerId: ownerId, client: client)
            syncMonitor.lastSyncDate = .now
        } catch {
            syncMonitor.lastErrorMessage = error.localizedDescription
        }
    }

    private func pullRemoteData(ownerId: String, client: SupabaseClient) async throws {
        let remoteSubjects: [RemoteSubject] = try await client.from("subjects").select().eq("owner_id", value: ownerId).execute().value
        for remote in remoteSubjects {
            try subjectRepository.upsertRemoteSubject(remote)
        }

        let localSubjects = try subjectRepository.fetchActive(ownerId: ownerId)
        let subjectsByID = Dictionary(uniqueKeysWithValues: localSubjects.map { ($0.id, $0) })

        let remoteMarks: [RemoteMarkEntry] = try await client.from("mark_entries").select().eq("owner_id", value: ownerId).execute().value
        for remote in remoteMarks {
            try markRepository.upsertRemoteMarkEntry(remote, subject: remote.subjectID.flatMap { subjectsByID[$0] })
        }

        let localMarks = try markRepository.fetchActive(ownerId: ownerId)
        let marksByID = Dictionary(uniqueKeysWithValues: localMarks.map { ($0.id, $0) })

        let remoteMistakes: [RemoteMistakeEntry] = try await client.from("mistake_entries").select().eq("owner_id", value: ownerId).execute().value
        for remote in remoteMistakes {
            try mistakeRepository.upsertRemoteMistakeEntry(
                remote,
                subject: remote.subjectID.flatMap { subjectsByID[$0] },
                markEntry: remote.markEntryID.flatMap { marksByID[$0] }
            )
        }
    }

    private func pushPendingDeletes(ownerId: String, client: SupabaseClient) async throws {
        let pendingMistakes = try mistakeRepository.pendingDeletes(ownerId: ownerId)
        for mistake in pendingMistakes {
            try await client.from("mistake_entries").delete().eq("id", value: mistake.id.uuidString.lowercased()).execute()
            if let photoPath = mistake.photoPath {
                _ = try? await client.storage.from(storageBucket).remove(paths: [storagePath(for: photoPath, ownerId: ownerId)])
                photoStore.delete(relativePath: photoPath)
            }
            try mistakeRepository.purge(mistake)
        }

        let pendingMarks = try markRepository.pendingDeletes(ownerId: ownerId)
        for mark in pendingMarks {
            try await client.from("mark_entries").delete().eq("id", value: mark.id.uuidString.lowercased()).execute()
            try markRepository.purge(mark)
        }

        let pendingSubjects = try subjectRepository.pendingDeletes(ownerId: ownerId)
        for subject in pendingSubjects {
            try await client.from("subjects").delete().eq("id", value: subject.id.uuidString.lowercased()).execute()
            try subjectRepository.purge(subject)
        }
    }

    private func pushPendingUploads(ownerId: String, client: SupabaseClient) async throws {
        let subjects = try subjectRepository.pendingUploads(ownerId: ownerId)
        for subject in subjects {
            let remote = RemoteSubject(subject: subject)
            try await client.from("subjects").upsert(remote).execute()
            try subjectRepository.markSynced(subject, updatedAt: .now)
        }

        let marks = try markRepository.pendingUploads(ownerId: ownerId)
        for mark in marks {
            let remote = RemoteMarkEntry(entry: mark)
            try await client.from("mark_entries").upsert(remote).execute()
            try markRepository.markSynced(mark, updatedAt: .now)
        }

        let mistakes = try mistakeRepository.pendingUploads(ownerId: ownerId)
        for mistake in mistakes {
            if let photoPath = mistake.photoPath, photoStore.fileExists(relativePath: photoPath) {
                let data = try photoStore.data(for: photoPath)
                try await client.storage.from(storageBucket).upload(
                    storagePath(for: photoPath, ownerId: ownerId),
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
            }

            let remote = RemoteMistakeEntry(entry: mistake)
            try await client.from("mistake_entries").upsert(remote).execute()
            try mistakeRepository.markSynced(mistake, updatedAt: .now)
        }
    }

    private func storagePath(for relativePath: String, ownerId: String) -> String {
        "\(ownerId)/\(relativePath)"
    }
}
