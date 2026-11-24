import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                permissionBanner
                modesSection
                startButton
                footerNote
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("PhotoClean")
        .navigationBarTitleDisplayMode(.large)
        .task {
            coordinator.permissionService.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Освободите место без потери лучших кадров")
                .font(.title2.weight(.semibold))
            Text("Сканирование и сравнение выполняются только на устройстве. Удалённые фото попадают в «Недавно удалённые».")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        let status = coordinator.permissionService.status
        if !status.canAccessLibrary || status == .limited || status == .notDetermined {
            VStack(alignment: .leading, spacing: 12) {
                Label(status.title, systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                Text(status.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if status == .notDetermined {
                        Button("Разрешить доступ") {
                            Task { await coordinator.permissionService.requestAccess() }
                        }
                        .buttonStyle(.borderedProminent)
                    } else if status == .denied || status == .restricted || status == .limited {
                        Button("Открыть Настройки") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
            )
        }
    }

    private var modesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Режимы очистки")
                .font(.title3.weight(.semibold))
            Text("Можно выбрать несколько — сканирование выполнит каждый по очереди.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(CleanupMode.allCases) { mode in
                ModeCard(
                    mode: mode,
                    isSelected: coordinator.selectedModes.contains(mode)
                ) {
                    coordinator.toggleMode(mode)
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            Task {
                let status = await coordinator.permissionService.requestAccess()
                guard status.canAccessLibrary else { return }
                coordinator.startScan()
            }
        } label: {
            Text("Сканировать")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(coordinator.selectedModes.isEmpty || coordinator.isScanning)
    }

    private var footerNote: some View {
        Text("Перед удалением вы сможете просмотреть группы и изменить выбор. Режим «Лучшие кадры» предлагает лучший снимок автоматически.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
