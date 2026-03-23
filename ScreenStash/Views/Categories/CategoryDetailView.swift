import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: ScreenshotCategory

    @Query private var allScreenshots: [Screenshot]

    private var screenshots: [Screenshot] {
        allScreenshots
            .filter { $0.category == category }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(screenshots) { screenshot in
                    NavigationLink(value: screenshot) {
                        ScreenshotGridItem(screenshot: screenshot)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.displayName)
        .navigationDestination(for: Screenshot.self) { screenshot in
            ScreenshotDetailView(screenshot: screenshot)
        }
        .overlay {
            if screenshots.isEmpty {
                ContentUnavailableView(
                    "No Screenshots",
                    systemImage: category.icon,
                    description: Text("No screenshots in this category yet.")
                )
            }
        }
    }
}
