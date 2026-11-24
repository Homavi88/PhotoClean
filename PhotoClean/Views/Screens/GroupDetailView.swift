import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    let groupID: UUID

    private var group: DuplicateGroup? {
        coordinator.group(with: groupID)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 10)
    ]

    var body: some View {
        Group {
            if let current = group {
                content(for: current) { updated in
                    coordinator.updateGroup(updated)
                }
            } else {
                ContentUnavailableView(
                    "Группа недоступна",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("Возможно, фото уже были удалены.")
                )
            }
        }
        .navigationTitle("Просмотр")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(
        for group: DuplicateGroup,
        onChange: @escaping (DuplicateGroup) -> Void
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(headerText(for: group))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if group.mode == .autoBest {
                    Text("Автовыбор лучшего кадра можно изменить: нажмите «Оставить» на другом фото.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(group.photos) { photo in
                        VStack(spacing: 8) {
                            PhotoThumbnailView(
                                photo: photo,
                                side: 120,
                                showsBestBadge: photo.id == group.suggestedKeepID,
                                isMarkedForDeletion: group.selectedForDeletion.contains(photo.id)
                            )
                            .onTapGesture {
                                var updated = group
                                updated.toggleDeletion(photo.id)
                                onChange(updated)
                            }

                            HStack(spacing: 8) {
                                Button("Оставить") {
                                    var updated = group
                                    updated.setKeep(photo.id)
                                    onChange(updated)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(photo.id == group.suggestedKeepID)

                                Button {
                                    var updated = group
                                    updated.toggleDeletion(photo.id)
                                    onChange(updated)
                                } label: {
                                    Image(systemName: group.selectedForDeletion.contains(photo.id)
                                          ? "trash.fill"
                                          : "trash")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(group.selectedForDeletion.contains(photo.id) ? .red : .secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func headerText(for group: DuplicateGroup) -> String {
        "\(group.mode.title) · \(group.photos.count) фото · к удалению \(group.selectedForDeletion.count)"
    }
}
