//
//  PapaHubShortcuts.swift
//  AsaPapaHub
//
//  App Shortcuts プロバイダー
//  Siriフレーズの登録とショートカット定義
//

import AppIntents

// MARK: - PapaHubShortcuts

/// パパハブの App Shortcuts プロバイダー
struct PapaHubShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MorningScoreIntent(),
            phrases: [
                "今日の朝活スコアは \(.applicationName)",
                "\(.applicationName) で朝活スコアを教えて",
                "\(.applicationName) の今日のスコア",
            ],
            shortTitle: "朝活スコア",
            systemImageName: "sunrise.fill"
        )

        AppShortcut(
            intent: WeeklySummaryIntent(),
            phrases: [
                "今週のサマリーを教えて \(.applicationName)",
                "\(.applicationName) の週間レポート",
                "\(.applicationName) で今週の振り返り",
            ],
            shortTitle: "週間サマリー",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: QuickEntryIntent(),
            phrases: [
                "\(.applicationName) で記録して",
                "\(.applicationName) にメモ",
                "\(.applicationName) でクイック記録",
            ],
            shortTitle: "クイック記録",
            systemImageName: "plus.circle.fill"
        )
    }
}
