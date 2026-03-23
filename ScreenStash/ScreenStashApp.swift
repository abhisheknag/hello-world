import SwiftUI
import SwiftData

@main
struct ScreenStashApp: App {
    @State private var subscriptionManager = SubscriptionManager()
    @State private var pipeline = ProcessingPipeline()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionManager)
                .environment(pipeline)
                .task {
                    subscriptionManager.start()
                }
                .task {
                    await processScreenshots()
                }
        }
        .modelContainer(for: Screenshot.self)
    }

    @MainActor
    private func processScreenshots() async {
        // Get the model context from the container
        guard let container = try? ModelContainer(for: Screenshot.self) else { return }
        let context = container.mainContext

        // Find the most recently processed screenshot date for delta sync
        let descriptor = FetchDescriptor<Screenshot>(
            sortBy: [SortDescriptor(\Screenshot.processedAt, order: .reverse)]
        )
        let lastProcessed = try? context.fetch(descriptor).first
        let lastSyncDate = lastProcessed?.processedAt

        await pipeline.processNewScreenshots(
            modelContext: context,
            since: lastSyncDate
        )
    }
}
