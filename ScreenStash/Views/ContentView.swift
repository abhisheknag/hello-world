import SwiftUI

struct ContentView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ProcessingPipeline.self) private var pipeline
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }

    private var mainTabView: some View {
        TabView {
            Tab("Library", systemImage: "photo.on.rectangle.angled") {
                LibraryView()
            }

            Tab("Categories", systemImage: "square.grid.2x2.fill") {
                CategoriesView()
            }

            Tab("Search", systemImage: "magnifyingglass") {
                SearchView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .overlay(alignment: .top) {
            if pipeline.isProcessing {
                processingBanner
            }
        }
    }

    private var processingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Processing screenshots... \(pipeline.processedCount)/\(pipeline.totalCount)")
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.top, 4)
    }
}
