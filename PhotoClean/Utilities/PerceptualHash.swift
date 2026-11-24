import Foundation
import UIKit

/// 64-bit average hash (aHash) for similar-photo detection.
struct PerceptualHash: Hashable, Sendable {
    let value: UInt64

    /// Hamming distance between two hashes (0 = identical perception).
    func distance(to other: PerceptualHash) -> Int {
        (value ^ other.value).nonzeroBitCount
    }

    static func compute(from image: UIImage, side: Int = 8) -> PerceptualHash? {
        guard side > 0, side <= 16 else { return nil }
        guard let cgImage = ImageHasher.resizedGrayscale(image, side: side) else { return nil }
        guard let provider = cgImage.dataProvider,
              let data = provider.data else { return nil }

        let length = CFDataGetLength(data)
        let expected = side * side
        guard length >= expected else { return nil }

        let pointer = CFDataGetBytePtr(data)!
        var sum = 0
        for i in 0..<expected {
            sum += Int(pointer[i])
        }
        let average = sum / expected

        var hash: UInt64 = 0
        let bits = min(expected, 64)
        for i in 0..<bits {
            if Int(pointer[i]) >= average {
                hash |= (1 as UInt64) << UInt64(i)
            }
        }
        return PerceptualHash(value: hash)
    }
}
