import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Screenshot.createdAt, order: .reverse) private var screenshots: [Screenshot]
    @State private var searchText = ""
    @State private var showPaywall = false

    private var displayedScreenshots: [Screenshot] {
        let filtered: [Screenshot]
        if searchText.isEmpty {
            filtered = Array(screenshots)
        } else {
            filtered = screenshots.filter {
                $0.extractedText.localizedCaseInsensitiveContains(searchText)
            }
        }

        if subscriptionManager.isProUser {
            return filtered
        } else {
            return Array(filtered.prefix(ScreenshotCategory.freeScreenshotLimit))
        }
    }

    private var lockedCount: Int {
        guard !subscriptionManager.isProUser else { return 0 }
        return max(0, screenshots.count - ScreenshotCategory.freeScreenshotLimit)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if !subscriptionManager.isProUser && lockedCount > 0 {
                    upgradeNudgeBanner
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(displayedScreenshots) { screenshot in
                        NavigationLink(value: screenshot) {
                            ScreenshotGridItem(screenshot: screenshot)
                        }
                    }
                }
                .padding(.horizontal)

                if !subscriptionManager.isProUser && lockedCount > 0 {
                    lockedOverlay
                }
            }
            .navigationTitle("Screenshots")
            .searchable(text: $searchText, prompt: "Search extracted text")
            .onChange(of: searchText) {
                if !searchText.isEmpty && !subscriptionManager.isProUser {
                    searchText = ""
                    showPaywall = true
                }
            }
            .navigationDestination(for: Screenshot.self) { screenshot in
                ScreenshotDetailView(screenshot: screenshot)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var upgradeNudgeBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("You have \(lockedCount) more screenshots to organize")
                    .font(.subheadline)
                Spacer()
                Text("Upgrade")
                    .font(.subheadline.bold())
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var lockedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("\(lockedCount) screenshots locked")
                .font(.headline)
            Text("Upgrade to Pro to organize your entire library")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Unlock All") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}
