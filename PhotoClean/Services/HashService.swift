import Foundation
import UIKit

struct HashedPhoto: Sendable {
    let photo: PhotoAsset
    let exactHash: String
    let perceptualHash: PerceptualHash?
}

/// Computes exact and perceptual hashes for photo assets.
actor HashService {
    private let library: PhotoLibraryService

    init(library: PhotoLibraryService) {
        self.library = library
    }

    func hashPhotos(
        _ photos: [PhotoAsset],
        needPerceptual: Bool,
        progress: @Sendable (Int, Int) -> Void
    ) async -> [HashedPhoto] {
        var results: [HashedPhoto] = []
        results.reserveCapacity(photos.count)
        let total = photos.count

        for (index, photo) in photos.enumerated() {
            if Task.isCancelled { break }

            var exact: String?
            if let data = await library.requestOriginalData(for: photo.localIdentifier), !data.isEmpty {
                exact = ImageHasher.sha256(of: data)
            }

            let analysisImage = await library.requestImageForAnalysis(for: photo.localIdentifier, maxSide: 256)
            if exact == nil, let analysisImage {
                exact = ImageHasher.pixelFingerprint(from: analysisImage)
            }

            let pHash: PerceptualHash? = needPerceptual
                ? analysisImage.flatMap { PerceptualHash.compute(from: $0) }
                : nil

            if let exact {
                results.append(HashedPhoto(photo: photo, exactHash: exact, perceptualHash: pHash))
            }

            progress(index + 1, total)
        }

        return results
    }
}
