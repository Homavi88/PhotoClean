import Foundation

/// Modes available for cleaning the photo library.
enum CleanupMode: String, CaseIterable, Identifiable, Sendable {
    case exactDuplicates
    case similarPhotos
    case autoBest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exactDuplicates: return "Точные дубликаты"
        case .similarPhotos: return "Похожие фото"
        case .autoBest: return "Лучшие кадры"
        }
    }

    var subtitle: String {
        switch self {
        case .exactDuplicates:
            return "Находит идентичные файлы по хешу содержимого"
        case .similarPhotos:
            return "Группирует визуально похожие снимки"
        case .autoBest:
            return "Выбирает лучший кадр; можно изменить перед удалением"
        }
    }

    var systemImage: String {
        switch self {
        case .exactDuplicates: return "doc.on.doc"
        case .similarPhotos: return "rectangle.on.rectangle.angled"
        case .autoBest: return "star.circle"
        }
    }
}
