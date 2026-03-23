import SwiftUI
import Photos

struct ScreenshotDetailView: View {
    let screenshot: Screenshot
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var fullImage: UIImage?
    @State private var showPaywall = false
    @State private var copiedText = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection
                categorySection
                extractedTextSection
                detectedEntitiesSection
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Screenshot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: screenshot.extractedText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task { await loadFullImage() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Sections

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let fullImage {
                Image(uiImage: fullImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let data = screenshot.thumbnailData,
                      let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay { ProgressView() }
            }
        }
    }

    private var categorySection: some View {
        HStack {
            Label(screenshot.category.displayName, systemImage: screenshot.category.icon)
                .font(.subheadline.bold())
                .foregroundStyle(screenshot.category.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(screenshot.category.color.opacity(0.15))
                .clipShape(Capsule())

            Spacer()

            Text(screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var extractedTextSection: some View {
        if !screenshot.extractedText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Extracted Text")
                        .font(.headline)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = screenshot.extractedText
                        copiedText = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedText = false
                        }
                    } label: {
                        Label(copiedText ? "Copied!" : "Copy", systemImage: copiedText ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text(screenshot.extractedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var detectedEntitiesSection: some View {
        let hasEntities = !screenshot.detectedURLs.isEmpty ||
                          !screenshot.detectedPhoneNumbers.isEmpty ||
                          !screenshot.detectedEmails.isEmpty

        if hasEntities {
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected")
                    .font(.headline)

                ForEach(screenshot.detectedURLs, id: \.self) { url in
                    entityRow(icon: "link", text: url, action: {
                        guard subscriptionManager.isProUser else {
                            showPaywall = true
                            return
                        }
                        if let url = URL(string: url) {
                            UIApplication.shared.open(url)
                        }
                    })
                }

                ForEach(screenshot.detectedPhoneNumbers, id: \.self) { phone in
                    entityRow(icon: "phone.fill", text: phone, action: {
                        guard subscriptionManager.isProUser else {
                            showPaywall = true
                            return
                        }
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    })
                }

                ForEach(screenshot.detectedEmails, id: \.self) { email in
                    entityRow(icon: "envelope.fill", text: email, action: {
                        guard subscriptionManager.isProUser else {
                            showPaywall = true
                            return
                        }
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    })
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            Button(role: .destructive) {
                deleteScreenshot()
            } label: {
                Label("Delete from Photos", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func entityRow(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(text)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                if !subscriptionManager.isProUser {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func loadFullImage() async {
        let importer = ScreenshotImporter()
        let fetchOptions = PHFetchOptions()
        let assetID = screenshot.assetLocalID
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetID)
        let result = PHAsset.fetchAssets(with: fetchOptions)
        guard let asset = result.firstObject else { return }
        fullImage = await importer.loadImage(for: asset)
    }

    private func deleteScreenshot() {
        let assetID = screenshot.assetLocalID
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetID)
        let assets = PHAsset.fetchAssets(with: fetchOptions)

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }
}
