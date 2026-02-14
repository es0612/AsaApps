import SwiftUI
import SwiftData
import AsaLifeLogKit
import TipKit

// MARK: - AsaLifeLogApp

/// ライフログ統合管理アプリ
///
/// 健康データ、位置情報、写真、アクティビティ、気分を統合タイムラインで管理し、
/// AIインサイトと美しいチャートで毎日を振り返る。
@main
struct AsaLifeLogApp: App {
    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            LifeLogEntry.self,
            DailySummary.self,
            WeeklySummary.self,
            PlaceLog.self,
            UserPreferences.self,
        ])
    }
}
