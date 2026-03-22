import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Screenshot.createdAt, order: .reverse) private var screenshots: [Screenshot]
    @State private var searchText = ""
    @State private var showPaywall = false

    private var results: [Screenshot] {
        guard !searchText.isEmpty else { return [] }
        return screenshots.filter {
            $0.extractedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if !subscriptionManager.isProUser {
                    proRequiredView
                } else if searchText.isEmpty {
                    emptySearchView
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(results) { screenshot in
                                NavigationLink(value: screenshot) {
                                    ScreenshotGridItem(screenshot: screenshot)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search text in screenshots")
            .navigationDestination(for: Screenshot.self) { screenshot in
                ScreenshotDetailView(screenshot: screenshot)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var emptySearchView: some View {
        ContentUnavailableView(
            "Search Screenshots",
            systemImage: "text.magnifyingglass",
            description: Text("Search across all text extracted from your screenshots.")
        )
    }

    private var proRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Search is a Pro Feature")
                .font(.title3.bold())

            Text("Upgrade to search across all text extracted from your \(screenshots.count) screenshots.")
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
}
