import Foundation
import SwiftData
import AsaPapaHubKit

// MARK: - サンプルデータローダー

/// 初回起動時にマスターデータを投入し、毎起動時に当日分を冪等補充するローダー
@MainActor
final class SampleDataLoader {
    private let modelContext: ModelContext
    private static let hasLoadedKey = "SampleDataLoaded_v1"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 初回マスター seed

    /// 初回起動時のみ実行。日付に依存しない不変データ（preferences, quickActions）を投入
    func loadIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: Self.hasLoadedKey) else { return }

        loadPreferences()
        loadQuickActions()

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: Self.hasLoadedKey)
    }

    // MARK: - 日次補充（毎起動・冪等）

    /// 毎起動時に呼び出し。当日分のデータが無ければ補充する。
    /// fetch().isEmpty 判定のため UserDefaults フラグとは独立に動作し、
    /// SwiftData ストア再生成や日付経過に対しても堅牢。
    func seedTodayIfMissing() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        seedTodayMorningRoutineIfMissing(today: today, tomorrow: tomorrow)
        seedTodayDomainSnapshotsIfMissing(today: today, tomorrow: tomorrow)
        seedRecent7DaysDashboardsIfMissing(today: today)
        seedTodayBriefingIfMissing(today: today, tomorrow: tomorrow)

        try? modelContext.save()
    }

    // MARK: - 不変マスター

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

    // MARK: - 日次補充ロジック

    /// 当日分の MorningRoutine が無ければ「5件中3件完了」の進行中状態で投入
    private func seedTodayMorningRoutineIfMissing(today: Date, tomorrow: Date) {
        let descriptor = FetchDescriptor<MorningRoutine>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { return }

        // 朝6時に起床して進行中、というデモ映えする状態
        let startTime = today.addingTimeInterval(6 * 3600)
        let routine = MorningRoutine(
            date: today,
            startTime: startTime,
            targetDurationMinutes: 60
        )
        modelContext.insert(routine)

        let items: [(String, Int, String, RoutineItemStatus)] = [
            ("起床・水分補給", 5, "cup.and.saucer.fill", .completed),
            ("ストレッチ", 10, "figure.cooldown", .completed),
            ("瞑想", 10, "brain.head.profile.fill", .completed),
            ("朝食準備", 20, "fork.knife", .pending),
            ("学習タイム", 15, "book.fill", .pending),
        ]

        for (index, (title, minutes, icon, status)) in items.enumerated() {
            let item = MorningRoutineItem(
                title: title,
                order: index,
                statusRawValue: status.rawValue,
                estimatedMinutes: minutes,
                actualMinutes: status == .completed ? minutes : nil,
                iconName: icon,
                routine: routine
            )
            modelContext.insert(item)
        }
    }

    /// 当日分の各ドメイン snapshot を未登録なら投入（6ドメイン個別に冪等判定）
    private func seedTodayDomainSnapshotsIfMissing(today: Date, tomorrow: Date) {
        let snapshotData: [(LifeDomain, Int, String, TrendDirection)] = [
            (.morning, 85, "朝活スコア好調。5日連続で早起き達成中です。", .up),
            (.health, 78, "歩数目標まであと少し。睡眠の質は良好です。", .stable),
            (.family, 92, "家族の写真を5枚追加。週末のお出かけ予定あり。", .up),
            (.finance, 70, "今月の支出は予算内。投資信託の評価額が上昇中。", .up),
            (.community, 65, "地域の防災訓練に参加予定。イベント2件チェック済み。", .stable),
            (.learning, 80, "SwiftUI学習 30分完了。フラッシュカード復習済み。", .up),
        ]

        for (domain, score, summary, trend) in snapshotData {
            let domainRaw = domain.rawValue
            let descriptor = FetchDescriptor<DomainSnapshot>(
                predicate: #Predicate {
                    $0.date >= today && $0.date < tomorrow && $0.domainRawValue == domainRaw
                }
            )
            guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { continue }

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

    /// 直近7日分の HubDashboard を冪等補充。空の日付だけ insert することで履歴がスライドする
    private func seedRecent7DaysDashboardsIfMissing(today: Date) {
        let calendar = Calendar.current

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else { continue }

            let descriptor = FetchDescriptor<HubDashboard>(
                predicate: #Predicate { $0.date >= date && $0.date < nextDay }
            )
            guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { continue }

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

    /// 当日分の DailyBriefing が無ければ投入
    private func seedTodayBriefingIfMissing(today: Date, tomorrow: Date) {
        let descriptor = FetchDescriptor<DailyBriefing>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { return }

        let briefing = DailyBriefing(
            date: today,
            greeting: "おはようございます！今日も素敵な朝ですね。",
            scheduleOverview: "今日は地域の防災訓練（10:00）と、子供の習い事（15:00）があります。",
            healthAdvice: "昨日の睡眠は7時間でした。今日も規則正しい生活を心がけましょう。",
            motivationalMessage: "100本ノック完走おめでとうございます！あなたの継続力は素晴らしいです。",
            statusRawValue: BriefingStatus.completed.rawValue
        )
        modelContext.insert(briefing)
    }
}
