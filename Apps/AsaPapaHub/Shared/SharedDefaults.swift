//
//  SharedDefaults.swift
//  AsaPapaHub
//
//  アプリとWidget間で共有するUserDefaults
//  App Group を使用したデータ共有
//

import Foundation

// MARK: - SharedDefaults

/// アプリとWidget間で共有するUserDefaults
enum SharedDefaults {
    static let suiteName = "group.com.asapapa.apps.asapapahub"
    static let widgetDataKey = "papahub_widget_data"

    static var suite: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Keys

    enum Keys {
        static let widgetData = "papahub_widget_data"
        static let lastUpdated = "papahub_last_updated"
    }

    // MARK: - Widget Data

    /// ウィジェットデータを保存
    static func saveWidgetData(_ data: PapaHubWidgetData) {
        if let encoded = try? JSONEncoder().encode(data) {
            shared.set(encoded, forKey: Keys.widgetData)
            shared.set(Date(), forKey: Keys.lastUpdated)
        }
    }

    /// ウィジェットデータを読み込み
    static func loadWidgetData() -> PapaHubWidgetData? {
        guard let data = shared.data(forKey: Keys.widgetData) else { return nil }
        return try? JSONDecoder().decode(PapaHubWidgetData.self, from: data)
    }

    /// 最終更新日時を取得
    static var lastUpdated: Date? {
        shared.object(forKey: Keys.lastUpdated) as? Date
    }
}
