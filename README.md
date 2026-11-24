# PhotoClean

Нативное iOS-приложение на **Swift / SwiftUI** для очистки медиатеки: точные дубликаты, похожие фото и автовыбор лучшего кадра с ручным подтверждением перед удалением.

Сканирование выполняется **только на устройстве**. Удаление идёт через Photos API в альбом **«Недавно удалённые»** (восстановление до 30 дней).

## Требования

- macOS с **Xcode 16+** (рекомендуется актуальный Xcode под iPhone 17 Pro)
- iOS **18.0+** (целевое устройство: iPhone, в т.ч. iPhone 17 Pro)
- Apple ID / Development Team для запуска на устройстве и TestFlight

## Быстрый старт

1. Клонируйте репозиторий и откройте проект:

```bash
git clone https://github.com/Homavi88/PhotoClean.git
cd PhotoClean
open PhotoClean.xcodeproj
```

2. В Xcode выберите target **PhotoClean**.
3. Укажите свою **Team** в *Signing & Capabilities* (Automatic signing).
4. При желании смените placeholder bundle id:

   `com.example.PhotoClean` → например `com.yourname.PhotoClean`

5. Выберите симулятор или подключённый iPhone → **Run** (⌘R).

## Разрешения (Photos)

В `PhotoClean/Resources/Info.plist` уже заданы ключи:

| Ключ | Назначение |
|------|------------|
| `NSPhotoLibraryUsageDescription` | Чтение медиатеки для сканирования |
| `NSPhotoLibraryAddUsageDescription` | Совместимость с Photos API |
| `PHPhotoLibraryPreventAutomaticLimitedAccessAlert` | Контроль limited-access UX в приложении |

При первом сканировании система покажет системный диалог доступа. Для полного результата нужен доступ ко **всем фото** (не только выбранным).

На симуляторе добавьте тестовые изображения через *Photos* или перетаскивание в приложение «Фото».

## Пользовательский поток

1. **Выбор режимов** на главном экране (можно несколько сразу):
   - Точные дубликаты (SHA-256 / fingerprint)
   - Похожие фото (perceptual aHash)
   - Лучшие кадры (похожие + автоkeep + ручной override)
2. **Сканирование** с прогрессом
3. **Группы** → превью → выбор keep / delete
4. **Удаление** → Photos перемещает файлы в «Недавно удалённые»

## Структура проекта

```
PhotoClean/
├── App/                 # Точка входа, корневой NavigationStack
├── Models/              # CleanupMode, PhotoAsset, DuplicateGroup, ScanProgress
├── Services/            # Permissions, Photos, hash, similarity, scan, delete
├── ViewModels/          # AppCoordinator
├── Views/
│   ├── Components/
│   └── Screens/         # Home → Scan → Groups → Detail
├── Utilities/           # SHA-256, perceptual hash, formatters
└── Resources/           # Info.plist, Assets, PrivacyInfo.xcprivacy
PhotoClean.xcodeproj/
```

## Запуск на устройстве

1. Подключите iPhone, доверьте компьютеру.
2. В Signing выберите Team; Xcode создаст provisioning profile.
3. При необходимости: на iPhone *Настройки → Основные → VPN и управление устройством* — доверьте разработчику.
4. Разрешите доступ к Фото при запросе приложения.

## TestFlight (позже, без публикации в App Store Review «на продажу»)

Проект уже подготовлен под дистрибуцию:

- Bundle ID placeholder: `com.example.PhotoClean` (замените на свой уникальный в App Store Connect)
- Версия: `1.0.0` / build `1`
- `PrivacyInfo.xcprivacy` (без трекинга, без сбора данных)
- Privacy usage strings в Info.plist
- Shared scheme `PhotoClean` с Archive

Краткие шаги:

1. Создайте App ID и приложение в [App Store Connect](https://appstoreconnect.apple.com) с вашим bundle id.
2. В Xcode: *Product → Archive*.
3. *Distribute App → App Store Connect → Upload*.
4. В App Store Connect добавьте сборку в **TestFlight** (Internal и/или External testing).
5. App Store **публиковать не обязательно** — TestFlight достаточно для проверки.

Перед внешним тестированием Apple может запросить краткий Beta App Review; для internal testers (в вашей команде) обычно достаточно.

## Ограничения и заметки

- Анализ больших библиотек может занять время (особенно режимы с perceptual hash).
- iCloud-фото подгружаются при необходимости (`isNetworkAccessAllowed = true`).
- Качество «лучшего кадра» оценивается эвристикой (разрешение, размер файла, избранное, соотношение сторон) — перед удалением всегда можно переопределить вручную.
- Иконка App Icon пока placeholder: добавьте 1024×1024 в `Assets.xcassets/AppIcon` перед TestFlight для внешнего теста.

## Лицензия

Private / unpublished — по решению владельца репозитория.
