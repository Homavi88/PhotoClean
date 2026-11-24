import Foundation
import Photos
import UIKit

/// Lightweight wrapper around a Photos library asset used throughout the app.
struct PhotoAsset: Identifiable, Hashable, Sendable {
    let id: String
    let localIdentifier: String
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let byteCount: Int64
    let isFavorite: Bool
    let mediaSubtype: PHAssetMediaSubtype

    var pixelCount: Int { pixelWidth * pixelHeight }

    var megapixels: Double {
        Double(pixelCount) / 1_000_000.0
    }

    init(asset: PHAsset, byteCount: Int64 = 0) {
        id = asset.localIdentifier
        localIdentifier = asset.localIdentifier
        creationDate = asset.creationDate
        pixelWidth = asset.pixelWidth
        pixelHeight = asset.pixelHeight
        self.byteCount = byteCount
        isFavorite = asset.isFavorite
        mediaSubtype = asset.mediaSubtypes
    }

    /// Quality score used by auto-best mode (higher is better).
    var qualityScore: Double {
        var score = Double(pixelCount)
        if isFavorite { score *= 1.25 }
        // Prefer larger file size as a proxy for less compression.
        score += Double(byteCount) * 0.0001
        // Slight preference for landscape / standard aspect ratios near 4:3 or 16:9.
        let ratio = Double(max(pixelWidth, 1)) / Double(max(pixelHeight, 1))
        let idealDeltas = [abs(ratio - 4.0 / 3.0), abs(ratio - 16.0 / 9.0), abs(ratio - 1.0)]
        let closeness = 1.0 / (1.0 + (idealDeltas.min() ?? 1.0))
        score *= (1.0 + closeness * 0.05)
        return score
    }
}
