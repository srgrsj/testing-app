import SwiftUI

struct RemoteThumbnailView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

struct RemoteGalleryView: View {
    let photos: [String]
    let itemWidth: CGFloat
    let itemHeight: CGFloat

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    AsyncImage(url: URL(string: photo)) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.15))
                                ProgressView()
                            }
                        case .failure:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.15))
                                Image(systemName: "photo.badge.exclamationmark")
                                    .foregroundStyle(.secondary)
                            }
                        @unknown default:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.15))
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(width: itemWidth, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Text("#\(index + 1)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
