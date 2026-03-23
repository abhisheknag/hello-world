import SwiftUI
import SwiftData
import Photos

struct DuplicatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(filter: #Predicate<Screenshot> { $0.isDuplicate }) private var duplicates: [Screenshot]
    @State private var showPaywall = false
    @State private var selectedForDeletion = Set<String>()

    private var duplicateGroups: [[Screenshot]] {
        var groups: [UUID: [Screenshot]] = [:]
        for screenshot in duplicates {
            if let groupID = screenshot.duplicateGroupID {
                groups[groupID, default: []].append(screenshot)
            }
        }
        return Array(groups.values).sorted { $0.first?.createdAt ?? .now > $1.first?.createdAt ?? .now }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !subscriptionManager.isProUser {
                    proRequiredView
                } else if duplicateGroups.isEmpty {
                    ContentUnavailableView(
                        "No Duplicates",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Your screenshot library is clean!")
                    )
                } else {
                    duplicatesList
                }
            }
            .navigationTitle("Duplicates")
            .toolbar {
                if subscriptionManager.isProUser && !selectedForDeletion.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete Selected (\(selectedForDeletion.count))") {
                            deleteSelected()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var duplicatesList: some View {
        List {
            ForEach(Array(duplicateGroups.enumerated()), id: \.offset) { _, group in
                Section("Group (\(group.count) screenshots)") {
                    ForEach(group) { screenshot in
                        HStack {
                            thumbnailView(screenshot)

                            VStack(alignment: .leading) {
                                Text(screenshot.category.displayName)
                                    .font(.subheadline.bold())
                                Text(screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                toggleSelection(screenshot.assetLocalID)
                            } label: {
                                Image(systemName: selectedForDeletion.contains(screenshot.assetLocalID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedForDeletion.contains(screenshot.assetLocalID) ? .red : .secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var proRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Duplicate Detection is Pro")
                .font(.title3.bold())

            Text("Find and remove duplicate screenshots to free up space.")
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

    @ViewBuilder
    private func thumbnailView(_ screenshot: Screenshot) -> some View {
        if let data = screenshot.thumbnailData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(width: 50, height: 50)
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedForDeletion.contains(id) {
            selectedForDeletion.remove(id)
        } else {
            selectedForDeletion.insert(id)
        }
    }

    private func deleteSelected() {
        let idsToDelete = selectedForDeletion
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier IN %@", Array(idsToDelete))
        let assets = PHAsset.fetchAssets(with: fetchOptions)

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        } completionHandler: { success, _ in
            if success {
                Task { @MainActor in
                    for id in idsToDelete {
                        let descriptor = FetchDescriptor<Screenshot>(
                            predicate: #Predicate { $0.assetLocalID == id }
                        )
                        if let screenshot = try? modelContext.fetch(descriptor).first {
                            modelContext.delete(screenshot)
                        }
                    }
                    selectedForDeletion.removeAll()
                }
            }
        }
    }
}
