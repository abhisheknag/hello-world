import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                cleanupSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            if subscriptionManager.isProUser {
                Label("ScreenStash Pro", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "sparkles")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
        }
    }

    private var cleanupSection: some View {
        Section("Cleanup") {
            NavigationLink {
                DuplicatesView()
            } label: {
                Label("Find Duplicates", systemImage: "doc.on.doc")
            }

            NavigationLink {
                BulkDeleteView()
            } label: {
                Label("Bulk Delete", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Privacy")
                Spacer()
                Text("All processing on-device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
