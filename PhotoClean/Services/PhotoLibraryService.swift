import Foundation
import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case permissionDenied
    case assetMissing
    case imageLoadFailed
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Нет доступа к медиатеке."
        case .assetMissing:
            return "Фото не найдено в библиотеке."
        case .imageLoadFailed:
            return "Не удалось загрузить изображение."
        case .deleteFailed(let message):
            return "Удаление не выполнено: \(message)"
        }
    }
}

/// Access layer for Photos framework assets and thumbnails.
actor PhotoLibraryService {
    private let imageManager = PHCachingImageManager()

    func fetchAllPhotoAssets() throws -> [PhotoAsset] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.permissionDenied
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        options.wantsIncrementalChangeDetails = false

        let result = PHAsset.fetchAssets(with: .image, options: options)
        var photos: [PhotoAsset] = []
        photos.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            let byteCount = resources
                .compactMap { $0.value(forKey: "fileSize") as? CLong }
                .map { Int64($0) }
                .max() ?? 0
            photos.append(PhotoAsset(asset: asset, byteCount: byteCount))
        }
        return photos
    }

    func phAsset(for localIdentifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
    }

    func requestThumbnail(
        for localIdentifier: String,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) async -> UIImage? {
        guard let asset = phAsset(for: localIdentifier) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                if cancelled {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }

    func requestImageForAnalysis(
        for localIdentifier: String,
        maxSide: CGFloat = 256
    ) async -> UIImage? {
        guard let asset = phAsset(for: localIdentifier) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let scale = await MainActor.run { UIScreen.main.scale }
        let target = CGSize(width: maxSide * scale, height: maxSide * scale)

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: target,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let error = info?[PHImageErrorKey] as? Error
                if cancelled || error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }

    func requestOriginalData(for localIdentifier: String) async -> Data? {
        guard let asset = phAsset(for: localIdentifier) else { return nil }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo }) ?? resources.first else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            var data = Data()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { chunk in
                    data.append(chunk)
                },
                completionHandler: { error in
                    if error != nil {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: data)
                    }
                }
            )
        }
    }

    func deleteAssets(withLocalIdentifiers ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        guard assets.count > 0 else { throw PhotoLibraryError.assetMissing }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: PhotoLibraryError.deleteFailed(error.localizedDescription))
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibraryError.deleteFailed("неизвестная ошибка"))
                }
            })
        }
    }
}
