import Foundation
import SwiftData

/// 学習分析データを表すSwift Dataモデル
/// 日別、週別の学習統計と朝活スコアを記録
@Model
final class LearningAnalytics {
    // MARK: - Core Properties

    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Daily Statistics

    /// 総学習時間（分）
    var totalMinutes: Int

    /// 完了セッション数
    var completedSessions: Int

    /// 完了学習項目数
    var completedItems: Int

    /// 朝活学習時間（5-9時）
    var morningMinutes: Int

    /// 深朝活学習時間（5-7時）
    var earlyMorningMinutes: Int

    // MARK: - Quality Metrics

    /// 平均集中度（1-5）
    var averageFocusLevel: Double

    /// 平均理解度（1-5）
    var averageComprehensionLevel: Double

    /// 計画達成率
    var planCompletionRate: Double

    // MARK: - Category Distribution (JSON)

    /// カテゴリ別学習時間（JSON: [String: Int]）
    var categoryMinutesJSON: Data?

    // MARK: - Streaks

    /// 連続学習日数
    var streakDays: Int

    /// 連続朝活日数
    var morningStreakDays: Int

    // MARK: - AI Feedback

    /// AI予測採用数
    var aiAcceptedCount: Int

    /// AI予測却下数
    var aiRejectedCount: Int

    // MARK: - Computed Properties

    var categoryMinutes: [String: Int] {
        get {
            guard let data = categoryMinutesJSON else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            categoryMinutesJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 朝活スコア（0-100）
    /// 深朝活はボーナス加算
    var morningScore: Int {
        let baseScore = min(morningMinutes, 120) / 2  // 最大60点（120分で満点）
        let bonusScore = min(earlyMorningMinutes, 60) / 3  // 最大20点（60分で満点）
        let streakBonus = min(morningStreakDays * 2, 20)  // 最大20点
        return min(baseScore + bonusScore + streakBonus, 100)
    }

    /// AI採用率
    var aiAcceptanceRate: Double {
        let total = aiAcceptedCount + aiRejectedCount
        guard total > 0 else { return 0 }
        return Double(aiAcceptedCount) / Double(total)
    }

    /// 生産性スコア（0-100）
    var productivityScore: Int {
        let timeScore = min(totalMinutes, 180) / 3  // 最大60点
        let focusScore = Int(averageFocusLevel * 10)  // 最大50点
        let completionScore = Int(planCompletionRate * 30)  // 最大30点
        return min((timeScore + focusScore + completionScore) / 2, 100)
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        date: Date
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
        self.updatedAt = Date()

        self.totalMinutes = 0
        self.completedSessions = 0
        self.completedItems = 0
        self.morningMinutes = 0
        self.earlyMorningMinutes = 0

        self.averageFocusLevel = 0.0
        self.averageComprehensionLevel = 0.0
        self.planCompletionRate = 0.0

        self.categoryMinutesJSON = nil

        self.streakDays = 0
        self.morningStreakDays = 0

        self.aiAcceptedCount = 0
        self.aiRejectedCount = 0
    }

    // MARK: - Methods

    /// セッション完了を記録
    func recordSession(_ session: StudySession, category: StudyCategory) {
        guard session.isCompleted else { return }

        totalMinutes += session.actualMinutes
        completedSessions += 1

        if session.isMorningSession {
            morningMinutes += session.actualMinutes
        }
        if session.isEarlyMorning {
            earlyMorningMinutes += session.actualMinutes
        }

        // カテゴリ別時間更新
        var catMinutes = categoryMinutes
        catMinutes[category.rawValue, default: 0] += session.actualMinutes
        categoryMinutes = catMinutes

        // 平均値更新
        let prevTotal = completedSessions - 1
        averageFocusLevel = (averageFocusLevel * Double(prevTotal) + Double(session.focusLevel)) / Double(completedSessions)
        averageComprehensionLevel = (averageComprehensionLevel * Double(prevTotal) + Double(session.comprehensionLevel)) / Double(completedSessions)

        updatedAt = Date()
    }

    /// AI予測フィードバックを記録
    func recordAIFeedback(accepted: Bool) {
        if accepted {
            aiAcceptedCount += 1
        } else {
            aiRejectedCount += 1
        }
        updatedAt = Date()
    }

    /// ストリーク更新
    func updateStreaks(didStudyToday: Bool, didMorningStudy: Bool) {
        if didStudyToday {
            streakDays += 1
        } else {
            streakDays = 0
        }

        if didMorningStudy {
            morningStreakDays += 1
        } else {
            morningStreakDays = 0
        }
        updatedAt = Date()
    }
}
