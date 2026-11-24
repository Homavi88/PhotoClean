import Foundation

struct ScanProgress: Sendable, Equatable {
    var phase: Phase
    var processed: Int
    var total: Int
    var groupsFound: Int
    var statusMessage: String

    enum Phase: String, Sendable {
        case idle
        case requestingPermission
        case loadingAssets
        case hashing
        case comparing
        case grouping
        case finished
        case failed
    }

    static let idle = ScanProgress(
        phase: .idle,
        processed: 0,
        total: 0,
        groupsFound: 0,
        statusMessage: "Готово к сканированию"
    )

    var fraction: Double {
        guard total > 0 else { return phase == .finished ? 1 : 0 }
        return min(1, Double(processed) / Double(total))
    }
}
