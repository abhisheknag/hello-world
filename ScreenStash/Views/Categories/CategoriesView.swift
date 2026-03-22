import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var screenshots: [Screenshot]
    @State private var showPaywall = false

    private var categoryCounts: [(category: ScreenshotCategory, count: Int)] {
        var counts: [ScreenshotCategory: Int] = [:]
        for screenshot in screenshots {
            counts[screenshot.category, default: 0] += 1
        }
        return ScreenshotCategory.allCases
            .map { (category: $0, count: counts[$0] ?? 0) }
            .filter { $0.count > 0 }
    }

    private func isCategoryLocked(_ category: ScreenshotCategory) -> Bool {
        !subscriptionManager.isProUser && !ScreenshotCategory.freeCategories.contains(category)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(categoryCounts, id: \.category) { item in
                        if isCategoryLocked(item.category) {
                            lockedCategoryCard(item.category, count: item.count)
                        } else {
                            NavigationLink(value: item.category) {
                                categoryCard(item.category, count: item.count)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .navigationDestination(for: ScreenshotCategory.self) { category in
                CategoryDetailView(category: category)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func categoryCard(_ category: ScreenshotCategory, count: Int) -> some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title)
                .foregroundStyle(category.color)

            Text(category.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(category.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func lockedCategoryCard(_ category: ScreenshotCategory, count: Int) -> some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: category.icon)
                        .font(.title)
                        .foregroundStyle(category.color.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .offset(x: 14, y: 14)
                }

                Text(category.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
