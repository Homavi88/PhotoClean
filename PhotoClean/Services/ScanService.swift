import Foundation

enum ScanError: LocalizedError {
    case cancelled
    case noPhotos
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Сканирование отменено."
        case .noPhotos: return "В медиатеке нет фотографий для анализа."
        case .underlying(let error): return error.localizedDescription
        }
    }
}

/// Orchestrates fetch → hash → group pipeline.
actor ScanService {
    private let library: PhotoLibraryService
    private let hasher: HashService

    init(library: PhotoLibraryService = PhotoLibraryService()) {
        self.library = library
        self.hasher = HashService(library: library)
    }

    func scan(
        mode: CleanupMode,
        progressHandler: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> [DuplicateGroup] {
        progressHandler(
            ScanProgress(
                phase: .loadingAssets,
                processed: 0,
                total: 0,
                groupsFound: 0,
                statusMessage: "Загрузка медиатеки…"
            )
        )

        let photos: [PhotoAsset]
        do {
            photos = try await library.fetchAllPhotoAssets()
        } catch {
            throw ScanError.underlying(error)
        }

        if Task.isCancelled { throw ScanError.cancelled }
        guard !photos.isEmpty else { throw ScanError.noPhotos }

        let needPerceptual = mode != .exactDuplicates

        progressHandler(
            ScanProgress(
                phase: .hashing,
                processed: 0,
                total: photos.count,
                groupsFound: 0,
                statusMessage: needPerceptual ? "Анализ изображений…" : "Подсчёт хешей…"
            )
        )

        let hashed = await hasher.hashPhotos(photos, needPerceptual: needPerceptual) { processed, total in
            progressHandler(
                ScanProgress(
                    phase: .hashing,
                    processed: processed,
                    total: total,
                    groupsFound: 0,
                    statusMessage: "Обработано \(processed) из \(total)"
                )
            )
        }

        if Task.isCancelled { throw ScanError.cancelled }

        progressHandler(
            ScanProgress(
                phase: .grouping,
                processed: hashed.count,
                total: hashed.count,
                groupsFound: 0,
                statusMessage: "Формирование групп…"
            )
        )

        let groups: [DuplicateGroup]
        switch mode {
        case .exactDuplicates:
            groups = SimilarityService.groupExactDuplicates(hashed)
        case .similarPhotos:
            groups = SimilarityService.groupSimilar(hashed)
        case .autoBest:
            groups = SimilarityService.groupAutoBest(hashed)
        }

        progressHandler(
            ScanProgress(
                phase: .finished,
                processed: hashed.count,
                total: hashed.count,
                groupsFound: groups.count,
                statusMessage: groups.isEmpty
                    ? "Дубликаты не найдены"
                    : "Найдено групп: \(groups.count)"
            )
        )

        return groups
    }
}
