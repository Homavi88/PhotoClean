import Foundation

enum PhotoCleanFormatters {
    static let bytes: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    static func bytes(_ value: Int64) -> String {
        bytes.string(fromByteCount: value)
    }
}
