import WidgetKit
import Foundation

// MARK: - LifeLogWidgetEntry

/// ウィジェット用タイムラインエントリー
struct LifeLogWidgetEntry: TimelineEntry {
    let date: Date
    let data: LifeLogWidgetData
}

// MARK: - LifeLogWidgetProvider

/// ウィジェットタイムラインプロバイダー
struct LifeLogWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeLogWidgetEntry {
        LifeLogWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeLogWidgetEntry) -> Void) {
        let data = SharedDefaults.loadWidgetData() ?? .placeholder
        completion(LifeLogWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeLogWidgetEntry>) -> Void) {
        let data = SharedDefaults.loadWidgetData() ?? LifeLogWidgetData()
        let entry = LifeLogWidgetEntry(date: Date(), data: data)

        // 30分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
