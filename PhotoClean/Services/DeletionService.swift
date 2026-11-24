import Foundation

struct DeletionResult: Sendable {
    let deletedCount: Int
    let reclaimedBytes: Int64
}

/// Deletes selected assets; Photos moves them to «Недавно удалённые».
actor DeletionService {
    private let library: PhotoLibraryService

    init(library: PhotoLibraryService = PhotoLibraryService()) {
        self.library = library
    }

    func delete(selectedFrom groups: [DuplicateGroup]) async throws -> DeletionResult {
        var ids: [String] = []
        var bytes: Int64 = 0
        var seen = Set<String>()

        for group in groups {
            for photo in group.deleteCandidates where !seen.contains(photo.id) {
                seen.insert(photo.id)
                ids.append(photo.localIdentifier)
                bytes += photo.byteCount
            }
        }

        guard !ids.isEmpty else {
            return DeletionResult(deletedCount: 0, reclaimedBytes: 0)
        }

        try await library.deleteAssets(withLocalIdentifiers: ids)
        return DeletionResult(deletedCount: ids.count, reclaimedBytes: bytes)
    }
}
