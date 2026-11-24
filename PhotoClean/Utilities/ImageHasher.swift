import Foundation
import CryptoKit
import CoreGraphics
import UIKit

/// Exact-content hashing for duplicate detection.
enum ImageHasher {
    /// SHA-256 of raw image bytes (or a compact pixel fingerprint fallback).
    static func sha256(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Fingerprint from a downscaled grayscale bitmap when original file bytes are unavailable.
    static func pixelFingerprint(from image: UIImage, side: Int = 32) -> String? {
        guard let cgImage = resizedGrayscale(image, side: side) else { return nil }
        guard let data = cgImage.dataProvider?.data as Data? else { return nil }
        return sha256(of: data)
    }

    static func resizedGrayscale(_ image: UIImage, side: Int) -> CGImage? {
        guard let source = image.cgImage else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: side, height: side))
        return context.makeImage()
    }
}
