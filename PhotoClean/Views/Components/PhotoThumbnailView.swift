import SwiftUI
import UIKit

struct PhotoThumbnailView: View {
    let photo: PhotoAsset
    let side: CGFloat
    var showsBestBadge: Bool = false
    var isMarkedForDeletion: Bool = false

    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
            }
            .frame(width: side, height: side)
            .clipped()
            .overlay {
                if isMarkedForDeletion {
                    Color.red.opacity(0.28)
                }
            }

            if showsBestBadge {
                Text("Лучшее")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(6)
            } else if isMarkedForDeletion {
                Image(systemName: "trash.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: photo.id) {
            image = await coordinator.loadThumbnail(for: photo, side: side)
        }
    }
}
