//
//  AsaSmartAlarmApp.swift
//  AsaSmartAlarm
//
//  天気や予定に応じたスマートアラームアプリ
//
//  Created by 朝活パパエンジニア
//

import SwiftUI
import SwiftData

// MARK: - メインアプリ

@main
struct AsaSmartAlarmApp: App {
    // MARK: - Properties

    /// Swift Dataのモデルコンテナ
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SmartAlarm.self,
            AlarmAdjustmentRule.self,
            CalendarEvent.self,
            AlarmSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("モデルコンテナの作成に失敗しました: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
