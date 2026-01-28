import Foundation
import SwiftData

/// 日別学習計画を表すSwift Dataモデル
/// AIが生成した最適化された学習スケジュールを管理
@Model
final class StudyPlan {
    // MARK: - Core Properties

    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Plan Items (JSON Encoded)

    /// 計画された学習項目の順序（StudyItemのID配列）
    var plannedItemIdsJSON: Data?

    /// 完了した学習項目ID
    var completedItemIdsJSON: Data?

    // MARK: - Plan Metrics

    /// 計画総学習時間（分）
    var totalPlannedMinutes: Int

    /// 実際の総学習時間（分）
    var actualTotalMinutes: Int

    /// AI最適化スコア（この計画の最適度）
    var optimizationScore: Double

    /// 計画達成率（0.0-1.0）
    var completionRate: Double

    // MARK: - Morning Activity

    /// 朝活目標時間（分）
    var morningGoalMinutes: Int

    /// 朝活実績時間（分）
    var morningActualMinutes: Int

    /// 朝活開始予定時刻
    var morningStartTime: Date?

    // MARK: - Status

    var isActive: Bool

    // MARK: - Computed Properties

    var plannedItemIds: [UUID] {
        get {
            guard let data = plannedItemIdsJSON else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            plannedItemIdsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    var completedItemIds: [UUID] {
        get {
            guard let data = completedItemIdsJSON else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            completedItemIdsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 計画対象日が今日かどうか
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// 計画対象日が過去かどうか
    var isPast: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }

    /// 朝活達成率
    var morningCompletionRate: Double {
        guard morningGoalMinutes > 0 else { return 0 }
        return min(Double(morningActualMinutes) / Double(morningGoalMinutes), 1.0)
    }

    /// 残り学習時間（分）
    var remainingMinutes: Int {
        max(0, totalPlannedMinutes - actualTotalMinutes)
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        date: Date,
        plannedItemIds: [UUID] = [],
        totalPlannedMinutes: Int = 0,
        morningGoalMinutes: Int = 60,
        morningStartTime: Date? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
        self.updatedAt = Date()

        self.plannedItemIdsJSON = try? JSONEncoder().encode(plannedItemIds)
        self.completedItemIdsJSON = try? JSONEncoder().encode([UUID]())

        self.totalPlannedMinutes = totalPlannedMinutes
        self.actualTotalMinutes = 0
        self.optimizationScore = 0.0
        self.completionRate = 0.0

        self.morningGoalMinutes = morningGoalMinutes
        self.morningActualMinutes = 0
        self.morningStartTime = morningStartTime

        self.isActive = true
    }

    // MARK: - Methods

    /// 学習項目完了を記録
    func markItemCompleted(_ itemId: UUID, minutes: Int, isMorning: Bool) {
        var completed = completedItemIds
        if !completed.contains(itemId) {
            completed.append(itemId)
            completedItemIds = completed
        }

        actualTotalMinutes += minutes
        if isMorning {
            morningActualMinutes += minutes
        }

        // 達成率更新
        completionRate = plannedItemIds.isEmpty ? 0 :
            Double(completedItemIds.count) / Double(plannedItemIds.count)

        updatedAt = Date()
    }

    /// 計画の最適化スコアを更新
    func updateOptimizationScore(_ score: Double) {
        optimizationScore = max(0, min(1, score))
        updatedAt = Date()
    }

    /// 計画をリセット
    func reset() {
        completedItemIds = []
        actualTotalMinutes = 0
        morningActualMinutes = 0
        completionRate = 0.0
        updatedAt = Date()
    }
}
