import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        List {
            summarySection
            ForEach(coordinator.groups) { group in
                Button {
                    coordinator.openGroup(group.id)
                } label: {
                    GroupRow(group: group)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Группы")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    coordinator.confirmDelete()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
                .disabled(coordinator.totalSelectedForDeletion == 0)
            }
        }
        .confirmationDialog(
            "Удалить выбранные фото?",
            isPresented: $coordinator.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Удалить \(coordinator.totalSelectedForDeletion) фото",
                role: .destructive
            ) {
                Task { await coordinator.performDelete() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Фото будут перемещены в «Недавно удалённые» и могут быть восстановлены в течение 30 дней.")
        }
        .overlay(alignment: .bottom) {
            if let banner = coordinator.deletionBanner {
                Text(banner)
                    .font(.footnote)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(4))
                            if coordinator.deletionBanner == banner {
                                coordinator.deletionBanner = nil
                            }
                        }
                    }
            }
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(coordinator.groups.count) групп · к удалению \(coordinator.totalSelectedForDeletion)")
                    .font(.headline)
                Text("Можно освободить ≈ \(PhotoCleanFormatters.bytes(coordinator.totalReclaimableBytes))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct GroupRow: View {
    let group: DuplicateGroup

    var body: some View {
        HStack(spacing: 12) {
            if let keep = group.keepPhoto {
                PhotoThumbnailView(
                    photo: keep,
                    side: 64,
                    showsBestBadge: group.mode == .autoBest,
                    isMarkedForDeletion: false
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.mode.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(group.photos.count) фото · удалить \(group.selectedForDeletion.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(PhotoCleanFormatters.bytes(group.estimatedReclaimableBytes))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
