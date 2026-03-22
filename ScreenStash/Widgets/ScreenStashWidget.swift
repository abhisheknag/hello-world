import WidgetKit
import SwiftUI
import SwiftData

struct ScreenStashWidget: Widget {
    let kind: String = "ScreenStashWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScreenStashTimelineProvider()) { entry in
            ScreenStashWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Screenshot Stats")
        .description("See your screenshot library status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ScreenStashEntry: TimelineEntry {
    let date: Date
    let totalCount: Int
    let duplicateCount: Int
    let recentCategories: [(category: ScreenshotCategory, count: Int)]
}

struct ScreenStashTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScreenStashEntry {
        ScreenStashEntry(
            date: .now,
            totalCount: 142,
            duplicateCount: 12,
            recentCategories: [(.receipt, 23), (.conversation, 45), (.code, 8)]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScreenStashEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScreenStashEntry>) -> Void) {
        // In production, query SwiftData via App Group shared container
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct ScreenStashWidgetView: View {
    let entry: ScreenStashEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo.stack.fill")
                    .foregroundStyle(.blue)
                Text("ScreenStash")
                    .font(.caption.bold())
            }

            Text("\(entry.totalCount)")
                .font(.system(size: 36, weight: .bold))

            Text("screenshots organized")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if entry.duplicateCount > 0 {
                Text("\(entry.duplicateCount) duplicates found")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack {
            smallWidget

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Top Categories")
                    .font(.caption.bold())

                ForEach(entry.recentCategories.prefix(3), id: \.category) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.category.icon)
                            .font(.caption2)
                            .foregroundStyle(item.category.color)
                        Text(item.category.displayName)
                            .font(.caption2)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption2.bold())
                    }
                }
            }
        }
    }
}
