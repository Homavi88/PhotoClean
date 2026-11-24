import Foundation

/// A set of photos considered duplicates or similar.
struct DuplicateGroup: Identifiable, Hashable, Sendable {
    let id: UUID
    let mode: CleanupMode
    var photos: [PhotoAsset]
    /// Asset suggested to keep (auto-best / default keep).
    var suggestedKeepID: String
    /// Currently selected assets marked for deletion.
    var selectedForDeletion: Set<String>

    init(
        id: UUID = UUID(),
        mode: CleanupMode,
        photos: [PhotoAsset],
        suggestedKeepID: String? = nil,
        selectedForDeletion: Set<String>? = nil
    ) {
        self.id = id
        self.mode = mode
        self.photos = photos
        let keep = suggestedKeepID ?? Self.pickBest(from: photos)?.id ?? photos.first?.id ?? ""
        self.suggestedKeepID = keep
        if let selectedForDeletion {
            self.selectedForDeletion = selectedForDeletion
        } else {
            self.selectedForDeletion = Set(photos.map(\.id).filter { $0 != keep })
        }
    }

    var keepPhoto: PhotoAsset? {
        photos.first { $0.id == suggestedKeepID } ?? photos.first
    }

    var deleteCandidates: [PhotoAsset] {
        photos.filter { selectedForDeletion.contains($0.id) }
    }

    var duplicateCount: Int { max(photos.count - 1, 0) }

    var estimatedReclaimableBytes: Int64 {
        deleteCandidates.reduce(0) { $0 + $1.byteCount }
    }

    mutating func setKeep(_ photoID: String) {
        guard photos.contains(where: { $0.id == photoID }) else { return }
        suggestedKeepID = photoID
        selectedForDeletion = Set(photos.map(\.id).filter { $0 != photoID })
    }

    mutating func toggleDeletion(_ photoID: String) {
        guard photos.contains(where: { $0.id == photoID }) else { return }
        if selectedForDeletion.contains(photoID) {
            // Don't allow deleting every photo — at least one must remain.
            if selectedForDeletion.count < photos.count - 1 || suggestedKeepID == photoID {
                selectedForDeletion.remove(photoID)
                if suggestedKeepID == photoID {
                    suggestedKeepID = photos.first { $0.id != photoID }?.id ?? suggestedKeepID
                }
            }
        } else {
            selectedForDeletion.insert(photoID)
            if suggestedKeepID == photoID {
                suggestedKeepID = photos.first { !selectedForDeletion.contains($0.id) }?.id ?? suggestedKeepID
            }
        }
    }

    static func pickBest(from photos: [PhotoAsset]) -> PhotoAsset? {
        photos.max { lhs, rhs in
            if lhs.qualityScore != rhs.qualityScore {
                return lhs.qualityScore < rhs.qualityScore
            }
            let lhsDate = lhs.creationDate ?? .distantPast
            let rhsDate = rhs.creationDate ?? .distantPast
            return lhsDate < rhsDate
        }
    }
}
