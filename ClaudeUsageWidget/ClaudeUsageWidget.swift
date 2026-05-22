import WidgetKit
import SwiftUI

private let appGroupID = "group.com.rekhlitskiy.usagetracerlimit"
private let cacheKey  = "cachedUsageData"

// MARK: - Provider

struct ClaudeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClaudeEntry {
        ClaudeEntry(date: Date(), data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeEntry) -> Void) {
        completion(ClaudeEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeEntry>) -> Void) {
        let entry = ClaudeEntry(date: Date(), data: loadData())
        let next  = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadData() -> ClaudeUsageData {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw  = defaults.data(forKey: cacheKey),
              let data = try? JSONDecoder().decode(ClaudeUsageData.self, from: raw)
        else { return .empty }
        return data
    }
}

// MARK: - Widget (no @main — Bundle in ClaudeUsageWidgetBundle.swift is the entry point)

struct ClaudeUsageWidget: Widget {
    let kind = "ClaudeUsageWidget"

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        return [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
        #else
        return [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClaudeProvider()) { entry in
            ClaudeWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Claude Usage")
        .description("5-hour and weekly Claude limits on your watch face")
        .supportedFamilies(Self.families)
    }
}
