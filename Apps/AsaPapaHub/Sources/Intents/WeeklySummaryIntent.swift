//
//  WeeklySummaryIntent.swift
//  AsaPapaHub
//
//  週間サマリーを確認するApp Intent
//  Siri: 「今週のサマリーを教えて AsaPapaHub」
//

import AppIntents
import SwiftData
import AsaPapaHubKit

// MARK: - WeeklySummaryIntent

/// 今週の週間サマリーを返す App Intent
struct WeeklySummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "週間サマリー"
    static let description: IntentDescription = IntentDescription("今週の朝活サマリーを確認します")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: HubDashboard.self)
        let context = container.mainContext

        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            return .result(dialog: "日付の計算に失敗しました。")
        }

        let descriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { dashboard in
                dashboard.date >= weekStart
            },
            sortBy: [SortDescriptor(\.date)]
        )

        let dashboards = try context.fetch(descriptor)

        if dashboards.isEmpty {
            return .result(dialog: "今週はまだ記録がありません。アプリを開いて今日の朝活を始めましょう！")
        }

        let avgScore = dashboards.map(\.morningScore).reduce(0, +) / dashboards.count
        let totalSteps = dashboards.map(\.stepsCount).reduce(0, +)
        let daysRecorded = dashboards.count

        let scoreComment: String
        if avgScore >= 80 {
            scoreComment = "絶好調です！"
        } else if avgScore >= 50 {
            scoreComment = "順調に進んでいます！"
        } else {
            scoreComment = "来週に向けて頑張りましょう！"
        }

        return .result(
            dialog: """
            今週の朝活サマリーです。\
            \(daysRecorded)日間の記録で、平均スコアは\(avgScore)点。\
            合計\(totalSteps)歩を歩きました。\
            \(scoreComment)
            """
        )
    }
}
