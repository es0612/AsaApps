//
//  MorningScoreIntent.swift
//  AsaPapaHub
//
//  今日の朝活スコアを確認するApp Intent
//  Siri: 「今日の朝活スコアは AsaPapaHub」
//

import AppIntents
import SwiftData
import AsaPapaHubKit

// MARK: - MorningScoreIntent

/// 今日の朝活スコアを返す App Intent
struct MorningScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "今日の朝活スコア"
    static let description: IntentDescription = IntentDescription("今日の朝活スコアを確認します")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: HubDashboard.self)
        let context = container.mainContext

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { dashboard in
                dashboard.date >= startOfDay && dashboard.date < endOfDay
            }
        )

        let dashboards = try context.fetch(descriptor)

        if let today = dashboards.first {
            let score = today.morningScore
            let comment: String
            if score >= 80 {
                comment = "素晴らしい朝を過ごしていますね！"
            } else if score >= 50 {
                comment = "いい調子です！もう少し頑張りましょう。"
            } else {
                comment = "まだまだこれから！一歩ずつ進みましょう。"
            }
            return .result(dialog: "今日の朝活スコアは\(score)点です！\(comment)")
        } else {
            return .result(dialog: "今日はまだ朝活の記録がありません。アプリを開いて記録を始めましょう！")
        }
    }
}
