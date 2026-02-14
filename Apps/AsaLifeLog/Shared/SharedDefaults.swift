import Foundation

// MARK: - SharedDefaults

/// アプリとWidget間で共有するUserDefaults
enum SharedDefaults {
    static let suiteName = "group.com.asapapa.apps.asalifelog"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Keys

    enum Keys {
        static let widgetData = "widget_data"
        static let lastUpdated = "last_updated"
    }

    // MARK: - Widget Data

    static func saveWidgetData(_ data: LifeLogWidgetData) {
        if let encoded = try? JSONEncoder().encode(data) {
            shared.set(encoded, forKey: Keys.widgetData)
            shared.set(Date(), forKey: Keys.lastUpdated)
        }
    }

    static func loadWidgetData() -> LifeLogWidgetData? {
        guard let data = shared.data(forKey: Keys.widgetData) else { return nil }
        return try? JSONDecoder().decode(LifeLogWidgetData.self, from: data)
    }
}
