import Foundation
import SwiftUI
import UIKit

enum AppRoute: Hashable {
    case scan(CleanupMode)
    case groups
    case groupDetail(UUID)
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedModes: Set<CleanupMode> = [.exactDuplicates]
    @Published var activeMode: CleanupMode = .exactDuplicates
    @Published var groups: [DuplicateGroup] = []
    @Published var progress: ScanProgress = .idle
    @Published var isScanning = false
    @Published var lastError: String?
    @Published var deletionBanner: String?
    @Published var showDeleteConfirmation = false

    let permissionService: PermissionService
    private let scanService: ScanService
    private let deletionService: DeletionService
    private let library: PhotoLibraryService
    private var scanTask: Task<Void, Never>?

    init(
        permissionService: PermissionService = PermissionService(),
        library: PhotoLibraryService = PhotoLibraryService()
    ) {
        self.permissionService = permissionService
        self.library = library
        self.scanService = ScanService(library: library)
        self.deletionService = DeletionService(library: library)
    }

    var totalSelectedForDeletion: Int {
        var seen = Set<String>()
        for group in groups {
            for id in group.selectedForDeletion {
                seen.insert(id)
            }
        }
        return seen.count
    }

    var totalReclaimableBytes: Int64 {
        var seen = Set<String>()
        var bytes: Int64 = 0
        for group in groups {
            for photo in group.deleteCandidates where !seen.contains(photo.id) {
                seen.insert(photo.id)
                bytes += photo.byteCount
            }
        }
        return bytes
    }

    func toggleMode(_ mode: CleanupMode) {
        if selectedModes.contains(mode) {
            if selectedModes.count > 1 {
                selectedModes.remove(mode)
            }
        } else {
            selectedModes.insert(mode)
        }
    }

    func startScan() {
        guard let mode = selectedModes.sorted(by: { $0.rawValue < $1.rawValue }).first else { return }
        // If multiple modes selected, run them sequentially and merge groups.
        path.append(AppRoute.scan(mode))
        scanTask?.cancel()
        scanTask = Task { await runScans(modes: Array(selectedModes)) }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        progress = ScanProgress(
            phase: .failed,
            processed: progress.processed,
            total: progress.total,
            groupsFound: groups.count,
            statusMessage: "Отменено"
        )
    }

    func openGroups() {
        path.append(AppRoute.groups)
    }

    func openGroup(_ id: UUID) {
        path.append(AppRoute.groupDetail(id))
    }

    func updateGroup(_ group: DuplicateGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
    }

    func group(with id: UUID) -> DuplicateGroup? {
        groups.first { $0.id == id }
    }

    func confirmDelete() {
        showDeleteConfirmation = true
    }

    func performDelete() async {
        showDeleteConfirmation = false
        do {
            let result = try await deletionService.delete(selectedFrom: groups)
            // Remove deleted assets from in-memory groups.
            var remaining: [DuplicateGroup] = []
            for var group in groups {
                group.photos.removeAll { group.selectedForDeletion.contains($0.id) }
                group.selectedForDeletion.removeAll()
                if group.photos.count > 1 {
                    if let best = DuplicateGroup.pickBest(from: group.photos) {
                        group.setKeep(best.id)
                    }
                    remaining.append(group)
                }
            }
            groups = remaining
            deletionBanner = result.deletedCount == 0
                ? "Нечего удалять"
                : "Удалено \(result.deletedCount) фото · \(PhotoCleanFormatters.bytes(result.reclaimedBytes)). Можно восстановить в «Недавно удалённые»."
        } catch {
            lastError = error.localizedDescription
        }
    }

    func loadThumbnail(for photo: PhotoAsset, side: CGFloat) async -> UIImage? {
        let scale = UIScreen.main.scale
        return await library.requestThumbnail(
            for: photo.localIdentifier,
            targetSize: CGSize(width: side * scale, height: side * scale)
        )
    }

    private func runScans(modes: [CleanupMode]) async {
        isScanning = true
        lastError = nil
        groups = []
        var merged: [DuplicateGroup] = []

        let ordered = CleanupMode.allCases.filter { modes.contains($0) }
        for mode in ordered {
            if Task.isCancelled { break }
            activeMode = mode
            do {
                let found = try await scanService.scan(mode: mode) { [weak self] progress in
                    Task { @MainActor in
                        self?.progress = progress
                    }
                }
                merged.append(contentsOf: found)
            } catch is CancellationError {
                break
            } catch let error as ScanError where error == .cancelled {
                break
            } catch {
                lastError = error.localizedDescription
                progress = ScanProgress(
                    phase: .failed,
                    processed: progress.processed,
                    total: progress.total,
                    groupsFound: merged.count,
                    statusMessage: error.localizedDescription
                )
                isScanning = false
                return
            }
        }

        groups = Self.deduplicateGroups(merged)
        isScanning = false
        if !Task.isCancelled {
            progress = ScanProgress(
                phase: .finished,
                processed: progress.total,
                total: max(progress.total, 1),
                groupsFound: groups.count,
                statusMessage: groups.isEmpty
                    ? "Лишних фото не найдено"
                    : "Готово: \(groups.count) групп"
            )
            if !groups.isEmpty {
                path.append(AppRoute.groups)
            }
        }
    }

    /// Prefer keeping distinct asset membership; drop near-identical group overlaps.
    private static func deduplicateGroups(_ groups: [DuplicateGroup]) -> [DuplicateGroup] {
        var seenSignatures = Set<String>()
        var result: [DuplicateGroup] = []
        for group in groups {
            let signature = group.photos.map(\.id).sorted().joined(separator: "|")
            if seenSignatures.insert(signature).inserted {
                result.append(group)
            }
        }
        return result
    }
}

extension ScanError: Equatable {
    static func == (lhs: ScanError, rhs: ScanError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled), (.noPhotos, .noPhotos):
            return true
        case (.underlying, .underlying):
            return false
        default:
            return false
        }
    }
}
