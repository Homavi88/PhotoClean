import Foundation
import Photos

enum PhotoPermissionStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    var canAccessLibrary: Bool {
        switch self {
        case .authorized, .limited: return true
        default: return false
        }
    }

    var title: String {
        switch self {
        case .notDetermined: return "Нужен доступ к Фото"
        case .authorized: return "Полный доступ"
        case .limited: return "Ограниченный доступ"
        case .denied: return "Доступ запрещён"
        case .restricted: return "Доступ ограничен"
        }
    }

    var message: String {
        switch self {
        case .notDetermined:
            return "PhotoClean анализирует библиотеку только на устройстве и не загружает фото в облако."
        case .authorized:
            return "Приложение может сканировать всю медиатеку."
        case .limited:
            return "Доступны только выбранные фото. Для полного результата откройте Настройки и выберите «Все фото»."
        case .denied, .restricted:
            return "Разрешите доступ к Фото в Настройках → PhotoClean, чтобы найти дубликаты."
        }
    }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var status: PhotoPermissionStatus

    init() {
        status = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func refresh() {
        status = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    @discardableResult
    func requestAccess() async -> PhotoPermissionStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .notDetermined {
            let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            let mapped = Self.map(result)
            status = mapped
            return mapped
        }
        let mapped = Self.map(current)
        status = mapped
        return mapped
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
}
