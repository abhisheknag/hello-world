import SwiftUI
import SwiftData
import Photos

struct BulkDeleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var screenshots: [Screenshot]
    @State private var selectedCategory: ScreenshotCategory?
    @State private var olderThan: Date = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
    @State private var showConfirmation = false
    @State private var showPaywall = false

    private var screenshotsToDelete: [Screenshot] {
        screenshots.filter { screenshot in
            let matchesCategory = selectedCategory == nil || screenshot.category == selectedCategory
            let matchesDate = screenshot.createdAt < olderThan
            return matchesCategory && matchesDate
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !subscriptionManager.isProUser {
                    proRequiredView
                } else {
                    filterForm
                }
            }
            .navigationTitle("Bulk Cleanup")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog(
                "Delete \(screenshotsToDelete.count) screenshots?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    performBulkDelete()
                }
            } message: {
                Text("This will remove them from your Photos library. This cannot be undone.")
            }
        }
    }

    private var filterForm: some View {
        Form {
            Section("Filter") {
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as ScreenshotCategory?)
                    ForEach(ScreenshotCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category as ScreenshotCategory?)
                    }
                }

                DatePicker("Older than", selection: $olderThan, displayedComponents: .date)
            }

            Section {
                HStack {
                    Text("Screenshots matching")
                    Spacer()
                    Text("\(screenshotsToDelete.count)")
                        .font(.headline)
                        .foregroundStyle(screenshotsToDelete.isEmpty ? .secondary : .red)
                }
            }

            Section {
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Label("Delete \(screenshotsToDelete.count) Screenshots", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .disabled(screenshotsToDelete.isEmpty)
            }
        }
    }

    private var proRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Bulk Cleanup is Pro")
                .font(.title3.bold())

            Text("Delete screenshots in bulk by category or date range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Upgrade to Pro") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func performBulkDelete() {
        let ids = screenshotsToDelete.map(\.assetLocalID)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier IN %@", ids)
        let assets = PHAsset.fetchAssets(with: fetchOptions)

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        } completionHandler: { success, _ in
            if success {
                Task { @MainActor in
                    for screenshot in screenshotsToDelete {
                        modelContext.delete(screenshot)
                    }
                }
            }
        }
    }
}
