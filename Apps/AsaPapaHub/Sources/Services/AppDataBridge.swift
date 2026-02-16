import Foundation
import SwiftData
import AsaPapaHubKit

// MARK: - アプリデータブリッジ

/// SwiftData ModelContext を使用してデータアクセスを提供するブリッジサービス
@MainActor
@Observable
final class AppDataBridge {
    private let modelContext: ModelContext

    // MARK: - キャッシュプロパティ

    var todayDashboard: HubDashboard?
    var todayRoutine: MorningRoutine?
    var domainSnapshots: [DomainSnapshot] = []
    var preferences: HubUserPreferences?
    var quickActions: [QuickAction] = []
    var todayBriefing: DailyBriefing?
    var recentDashboards: [HubDashboard] = []

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - データ読み込み

    func loadTodayData() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        // ダッシュボード取得
        let dashboardDescriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        todayDashboard = try? modelContext.fetch(dashboardDescriptor).first

        // ルーティン取得
        let routineDescriptor = FetchDescriptor<MorningRoutine>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        todayRoutine = try? modelContext.fetch(routineDescriptor).first

        // スナップショット取得
        let snapshotDescriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.domainRawValue)]
        )
        domainSnapshots = (try? modelContext.fetch(snapshotDescriptor)) ?? []

        // 設定取得
        let prefsDescriptor = FetchDescriptor<HubUserPreferences>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        preferences = try? modelContext.fetch(prefsDescriptor).first

        // クイックアクション取得
        let actionsDescriptor = FetchDescriptor<QuickAction>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.order)]
        )
        quickActions = (try? modelContext.fetch(actionsDescriptor)) ?? []

        // ブリーフィング取得
        let briefingDescriptor = FetchDescriptor<DailyBriefing>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        todayBriefing = try? modelContext.fetch(briefingDescriptor).first

        // 直近7日分のダッシュボード取得
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let recentDescriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        recentDashboards = (try? modelContext.fetch(recentDescriptor)) ?? []
    }

    // MARK: - ドメインスナップショット取得

    func snapshot(for domain: LifeDomain) -> DomainSnapshot? {
        domainSnapshots.first { $0.domain == domain }
    }

    // MARK: - ルーティン操作

    func startRoutine() {
        todayRoutine?.startTime = Date()
        try? modelContext.save()
    }

    func completeRoutineItem(_ item: MorningRoutineItem) {
        item.status = .completed
        item.actualMinutes = item.estimatedMinutes
        try? modelContext.save()
    }

    func skipRoutineItem(_ item: MorningRoutineItem) {
        item.status = .skipped
        try? modelContext.save()
    }

    func finishRoutine() {
        guard let routine = todayRoutine else { return }
        routine.endTime = Date()
        routine.isCompleted = true
        routine.totalScore = calculateRoutineScore(routine)
        todayDashboard?.morningScore = routine.totalScore
        try? modelContext.save()
    }

    // MARK: - 設定保存

    func savePreferences() {
        preferences?.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - スコア計算

    private func calculateRoutineScore(_ routine: MorningRoutine) -> Int {
        guard !routine.items.isEmpty else { return 0 }
        let completedCount = routine.items.filter { $0.status == .completed }.count
        let totalCount = routine.items.count
        return Int(Double(completedCount) / Double(totalCount) * 100)
    }
}
