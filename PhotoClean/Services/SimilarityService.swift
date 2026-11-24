import Foundation

/// Groups photos by exact hash or perceptual similarity.
enum SimilarityService {
    /// Exact duplicates: same SHA-256 / pixel fingerprint.
    static func groupExactDuplicates(_ hashed: [HashedPhoto]) -> [DuplicateGroup] {
        let buckets = Dictionary(grouping: hashed, by: \.exactHash)
        return buckets.values
            .filter { $0.count > 1 }
            .map { items in
                let photos = items.map(\.photo).sorted { lhs, rhs in
                    (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
                }
                return DuplicateGroup(mode: .exactDuplicates, photos: photos)
            }
            .sorted { $0.photos.count > $1.photos.count }
    }

    /// Similar photos via perceptual hash Hamming distance.
    /// - Parameter threshold: Max Hamming distance to consider similar (typical 0–10 for 64-bit aHash).
    static func groupSimilar(
        _ hashed: [HashedPhoto],
        threshold: Int = 8,
        mode: CleanupMode = .similarPhotos
    ) -> [DuplicateGroup] {
        let candidates = hashed.compactMap { item -> (PhotoAsset, PerceptualHash)? in
            guard let hash = item.perceptualHash else { return nil }
            return (item.photo, hash)
        }

        var assigned = Set<String>()
        var groups: [DuplicateGroup] = []

        for i in 0..<candidates.count {
            let (photo, hash) = candidates[i]
            if assigned.contains(photo.id) { continue }

            var cluster: [PhotoAsset] = [photo]
            assigned.insert(photo.id)

            for j in (i + 1)..<candidates.count {
                let (other, otherHash) = candidates[j]
                if assigned.contains(other.id) { continue }
                if hash.distance(to: otherHash) <= threshold {
                    cluster.append(other)
                    assigned.insert(other.id)
                }
            }

            if cluster.count > 1 {
                let sorted = cluster.sorted { lhs, rhs in
                    if lhs.qualityScore != rhs.qualityScore {
                        return lhs.qualityScore > rhs.qualityScore
                    }
                    return (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
                }
                groups.append(DuplicateGroup(mode: mode, photos: sorted))
            }
        }

        return groups.sorted { $0.photos.count > $1.photos.count }
    }

    /// Auto-best: same as similar grouping but mode marked for manual override UX.
    static func groupAutoBest(_ hashed: [HashedPhoto], threshold: Int = 8) -> [DuplicateGroup] {
        groupSimilar(hashed, threshold: threshold, mode: .autoBest)
    }
}
