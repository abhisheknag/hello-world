import SwiftUI

struct ScreenshotGridItem: View {
    let screenshot: Screenshot

    var body: some View {
        VStack(spacing: 0) {
            thumbnailView
                .overlay(alignment: .topTrailing) {
                    categoryBadge
                }

            if screenshot.isDuplicate {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.caption2)
                    Text("Duplicate")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
                .padding(4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = screenshot.thumbnailData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minHeight: 150, maxHeight: 200)
                .clipped()
        } else {
            Rectangle()
                .fill(.quaternary)
                .frame(minHeight: 150, maxHeight: 200)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var categoryBadge: some View {
        Image(systemName: screenshot.category.icon)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(6)
            .background(screenshot.category.color, in: Circle())
            .padding(6)
    }
}
