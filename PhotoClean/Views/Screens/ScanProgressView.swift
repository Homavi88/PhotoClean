import SwiftUI

struct ScanProgressView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    let mode: CleanupMode

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: mode.systemImage)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse, isActive: coordinator.isScanning)

            VStack(spacing: 8) {
                Text(mode.title)
                    .font(.title2.weight(.semibold))
                Text(coordinator.progress.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ProgressView(value: coordinator.progress.fraction)
                .progressViewStyle(.linear)
                .padding(.horizontal, 32)

            if coordinator.progress.total > 0 {
                Text("\(coordinator.progress.processed) / \(coordinator.progress.total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if coordinator.progress.groupsFound > 0 {
                Text("Групп найдено: \(coordinator.progress.groupsFound)")
                    .font(.subheadline.weight(.medium))
            }

            if let error = coordinator.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            if coordinator.isScanning {
                Button("Отменить", role: .destructive) {
                    coordinator.cancelScan()
                }
            } else if coordinator.progress.phase == .finished {
                if coordinator.groups.isEmpty {
                    ContentUnavailableView(
                        "Чисто",
                        systemImage: "checkmark.seal",
                        description: Text("Подходящих дубликатов не найдено.")
                    )
                } else {
                    Button("Показать группы") {
                        coordinator.openGroups()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer(minLength: 24)
        }
        .padding()
        .navigationTitle("Сканирование")
        .navigationBarTitleDisplayMode(.inline)
    }
}
