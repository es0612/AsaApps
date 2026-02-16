import Foundation
import SwiftData
import AsaPapaHubKit

// MARK: - サンプルデータローダー

/// 初回起動時にデモデータを投入するローダー
@MainActor
final class SampleDataLoader {
    private let modelContext: ModelContext
    private static let hasLoadedKey = "SampleDataLoaded_v1"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 読み込み判定

    func loadIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: Self.hasLoadedKey) else { return }

        loadPreferences()
        loadQuickActions()
        loadDashboards()
        loadMorningRoutine()
        loadDomainSnapshots()
        loadDailyBriefing()

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: Self.hasLoadedKey)
    }

    // MARK: - データ生成

    private func loadPreferences() {
        let prefs = HubUserPreferences()
        modelContext.insert(prefs)
    }

    private func loadQuickActions() {
        let actions: [(String, String, LifeDomain, Int)] = [
            ("朝活を始める", "sunrise.fill", .morning, 0),
            ("歩数を記録", "figure.walk", .health, 1),
            ("家族アルバム", "photo.on.rectangle", .family, 2),
            ("支出を記録", "yensign.circle", .finance, 3),
            ("学習を始める", "book.fill", .learning, 4),
            ("地域イベント", "calendar", .community, 5),
        ]

        for (title, icon, domain, order) in actions {
            let action = QuickAction(
                title: title,
                iconName: icon,
                domainRawValue: domain.rawValue,
                actionTypeRawValue: "navigate",
                isEnabled: true,
                order: order
            )
            modelContext.insert(action)
        }
    }

    private func loadDashboards() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 直近7日分のダッシュボード
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let score = max(0, 85 - dayOffset * 5 + Int.random(in: -10...10))
            let steps = max(0, 8500 - dayOffset * 300 + Int.random(in: -500...500))
            let sleep = max(5.0, 7.2 - Double(dayOffset) * 0.15 + Double.random(in: -0.5...0.5))

            let dashboard = HubDashboard(
                date: date,
                morningScore: score,
                stepsCount: steps,
                sleepHours: sleep,
                overallProgress: Double(score) / 100.0,
                activeDomainsRawValue: LifeDomain.allCases.map(\.rawValue).joined(separator: ",")
            )
            modelContext.insert(dashboard)
        }
    }

    private func loadMorningRoutine() {
        let today = Calendar.current.startOfDay(for: Date())
        let routine = MorningRoutine(date: today, targetDurationMinutes: 60)
        modelContext.insert(routine)

        let items: [(String, Int, String)] = [
            ("起床・水分補給", 5, "cup.and.saucer.fill"),
            ("ストレッチ", 10, "figure.cooldown"),
            ("瞑想", 10, "brain.head.profile.fill"),
            ("朝食準備", 20, "fork.knife"),
            ("学習タイム", 15, "book.fill"),
        ]

        for (index, (title, minutes, icon)) in items.enumerated() {
            let item = MorningRoutineItem(
                title: title,
                order: index,
                estimatedMinutes: minutes,
                iconName: icon,
                routine: routine
            )
            modelContext.insert(item)
        }
    }

    private func loadDomainSnapshots() {
        let today = Calendar.current.startOfDay(for: Date())

        let snapshots: [(LifeDomain, Int, String, TrendDirection)] = [
            (.morning, 85, "朝活スコア好調。5日連続で早起き達成中です。", .up),
            (.health, 78, "歩数目標まであと少し。睡眠の質は良好です。", .stable),
            (.family, 92, "家族の写真を5枚追加。週末のお出かけ予定あり。", .up),
            (.finance, 70, "今月の支出は予算内。投資信託の評価額が上昇中。", .up),
            (.community, 65, "地域の防災訓練に参加予定。イベント2件チェック済み。", .stable),
            (.learning, 80, "SwiftUI学習 30分完了。フラッシュカード復習済み。", .up),
        ]

        for (domain, score, summary, trend) in snapshots {
            let snapshot = DomainSnapshot(
                date: today,
                domainRawValue: domain.rawValue,
                score: score,
                summary: summary,
                trendRawValue: trend.rawValue
            )
            modelContext.insert(snapshot)
        }
    }

    private func loadDailyBriefing() {
        let briefing = DailyBriefing(
            greeting: "おはようございます！今日も素敵な朝ですね。",
            scheduleOverview: "今日は地域の防災訓練（10:00）と、子供の習い事（15:00）があります。",
            healthAdvice: "昨日の睡眠は7時間でした。今日も規則正しい生活を心がけましょう。",
            motivationalMessage: "100本ノック完走おめでとうございます！あなたの継続力は素晴らしいです。",
            statusRawValue: BriefingStatus.completed.rawValue
        )
        modelContext.insert(briefing)
    }
}
