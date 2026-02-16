//
//  PapaHubWidgetProvider.swift
//  PapaHubWidgetExtension
//
//  ウィジェットタイムラインプロバイダー
//  SharedDefaults経由でデータ取得・15分間隔更新
//

import WidgetKit
import Foundation

// MARK: - PapaHubWidgetEntry

/// ウィジェット用タイムラインエントリー
struct PapaHubWidgetEntry: TimelineEntry {
    let date: Date
    let data: PapaHubWidgetData
}

// MARK: - PapaHubWidgetProvider

/// ウィジェットタイムラインプロバイダー
struct PapaHubWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PapaHubWidgetEntry {
        PapaHubWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PapaHubWidgetEntry) -> Void) {
        let data = SharedDefaults.loadWidgetData() ?? .placeholder
        completion(PapaHubWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PapaHubWidgetEntry>) -> Void) {
        let data = SharedDefaults.loadWidgetData() ?? PapaHubWidgetData()
        let entry = PapaHubWidgetEntry(date: Date(), data: data)

        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
