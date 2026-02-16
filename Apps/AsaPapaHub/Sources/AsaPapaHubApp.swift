import SwiftUI
import SwiftData
import AsaPapaHubKit

// MARK: - AsaPapaHub アプリエントリポイント

/// 100本ノック完走記念 - 朝活パパのライフハブアプリ
@main
struct AsaPapaHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            HubDashboard.self,
            MorningRoutine.self,
            MorningRoutineItem.self,
            DomainSnapshot.self,
            HubUserPreferences.self,
            WeeklySummary.self,
            DailyBriefing.self,
            QuickAction.self
        ])
    }
}
