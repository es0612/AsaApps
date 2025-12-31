//
//  TaskAnalytics.swift
//  AsaSmartTodo
//
//  生産性分析とAI精度トラッキングのデータモデル
//  日別の統計情報を記録し、AI予測の精度改善に活用
//

import Foundation
import SwiftData

@Model
final class TaskAnalytics {
    // MARK: - 識別情報

    @Attribute(.unique) var id: UUID
    var date: Date  // 分析対象日（日付のみ、時刻は00:00:00）

    // MARK: - タスク統計

    /// 総タスク数
    var totalTasks: Int

    /// 完了したタスク数
    var completedTasks: Int

    /// 新規作成タスク数
    var createdTasks: Int

    /// 期限切れタスク数
    var overdueTasks: Int

    // MARK: - AI精度メトリクス

    /// 総予測数
    var totalPredictions: Int

    /// 採用された予測数
    var acceptedPredictions: Int

    /// 却下された予測数
    var rejectedPredictions: Int

    /// 平均信頼度スコア
    var averageConfidence: Double

    // MARK: - 時間帯別統計（JSON形式で保存）

    /// 時間帯別タスク作成数（24時間、0-23時）
    var hourlyTaskCreationJSON: Data?

    /// 時間帯別完了率（24時間、0-23時）
    var hourlyCompletionRateJSON: Data?

    // MARK: - 朝活スコア（5:00-7:00）

    /// 朝活時間帯に作成されたタスク数
    var earlyMorningTasksCreated: Int

    /// 朝活時間帯に完了したタスク数
    var earlyMorningTasksCompleted: Int

    /// 朝活生産性スコア（0.0-1.0）
    var earlyMorningProductivityScore: Double

    // MARK: - Computed Properties

    /// タスク完了率（0.0-1.0）
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }

    /// AI予測採用率（0.0-1.0）
    var aiAcceptanceRate: Double {
        guard totalPredictions > 0 else { return 0.0 }
        return Double(acceptedPredictions) / Double(totalPredictions)
    }

    /// 時間帯別タスク作成数（デコード）
    var hourlyTaskCreation: [Int] {
        get {
            guard let data = hourlyTaskCreationJSON else { return Array(repeating: 0, count: 24) }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? Array(repeating: 0, count: 24)
        }
        set {
            hourlyTaskCreationJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 時間帯別完了率（デコード）
    var hourlyCompletionRate: [Double] {
        get {
            guard let data = hourlyCompletionRateJSON else { return Array(repeating: 0.0, count: 24) }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? Array(repeating: 0.0, count: 24)
        }
        set {
            hourlyCompletionRateJSON = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Initializer

    init(date: Date) {
        self.id = UUID()

        // 日付のみを保持（時刻は00:00:00）
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)

        // タスク統計の初期化
        self.totalTasks = 0
        self.completedTasks = 0
        self.createdTasks = 0
        self.overdueTasks = 0

        // AI精度メトリクスの初期化
        self.totalPredictions = 0
        self.acceptedPredictions = 0
        self.rejectedPredictions = 0
        self.averageConfidence = 0.0

        // 時間帯別統計の初期化（24時間分）
        self.hourlyTaskCreationJSON = try? JSONEncoder().encode(Array(repeating: 0, count: 24))
        self.hourlyCompletionRateJSON = try? JSONEncoder().encode(Array(repeating: 0.0, count: 24))

        // 朝活スコアの初期化
        self.earlyMorningTasksCreated = 0
        self.earlyMorningTasksCompleted = 0
        self.earlyMorningProductivityScore = 0.0
    }

    // MARK: - Methods

    /// タスク作成を記録
    func recordTaskCreation(at hour: Int, category: TaskCategory) {
        guard hour >= 0 && hour < 24 else { return }

        var creation = hourlyTaskCreation
        creation[hour] += 1
        hourlyTaskCreation = creation

        createdTasks += 1
        totalTasks += 1

        // 朝活時間帯（5:00-7:00）の記録
        if hour >= 5 && hour < 7 {
            earlyMorningTasksCreated += 1
        }

        updateEarlyMorningScore()
    }

    /// タスク完了を記録
    func recordTaskCompletion(at hour: Int, category: TaskCategory) {
        guard hour >= 0 && hour < 24 else { return }

        completedTasks += 1

        // 時間帯別完了率の更新
        var rates = hourlyCompletionRate
        let creation = hourlyTaskCreation
        if creation[hour] > 0 {
            rates[hour] = Double(completedTasks) / Double(creation[hour])
        }
        hourlyCompletionRate = rates

        // 朝活時間帯の完了記録
        if hour >= 5 && hour < 7 {
            earlyMorningTasksCompleted += 1
        }

        updateEarlyMorningScore()
    }

    /// AI予測フィードバックを記録
    func recordAIFeedback(accepted: Bool, confidenceScore: Double) {
        totalPredictions += 1

        if accepted {
            acceptedPredictions += 1
        } else {
            rejectedPredictions += 1
        }

        // 移動平均で信頼度スコアを更新
        let previousTotal = Double(totalPredictions - 1)
        averageConfidence = (averageConfidence * previousTotal + confidenceScore) / Double(totalPredictions)
    }

    /// 期限切れタスクを記録
    func recordOverdueTask() {
        overdueTasks += 1
    }

    /// 朝活生産性スコアを更新
    private func updateEarlyMorningScore() {
        guard earlyMorningTasksCreated > 0 else {
            earlyMorningProductivityScore = 0.0
            return
        }

        let completionRate = Double(earlyMorningTasksCompleted) / Double(earlyMorningTasksCreated)
        earlyMorningProductivityScore = completionRate
    }

    /// 統計情報をリセット（新しい日用）
    func reset(for newDate: Date) {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: newDate)

        // すべての統計をリセット
        totalTasks = 0
        completedTasks = 0
        createdTasks = 0
        overdueTasks = 0

        totalPredictions = 0
        acceptedPredictions = 0
        rejectedPredictions = 0
        averageConfidence = 0.0

        hourlyTaskCreationJSON = try? JSONEncoder().encode(Array(repeating: 0, count: 24))
        hourlyCompletionRateJSON = try? JSONEncoder().encode(Array(repeating: 0.0, count: 24))

        earlyMorningTasksCreated = 0
        earlyMorningTasksCompleted = 0
        earlyMorningProductivityScore = 0.0
    }
}
