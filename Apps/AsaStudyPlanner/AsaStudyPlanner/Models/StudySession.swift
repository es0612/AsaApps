import Foundation
import SwiftData

/// 学習セッションを記録するSwift Dataモデル
/// 各セッションの時間、集中度、朝活判定などを記録
@Model
final class StudySession {
    // MARK: - Core Properties

    @Attribute(.unique) var id: UUID
    var studyItemId: UUID
    var startedAt: Date
    var endedAt: Date?

    // MARK: - Session Metrics

    /// 予定学習時間（分）
    var plannedMinutes: Int

    /// 実際の学習時間（分）
    var actualMinutes: Int

    /// 集中度（1-5）
    /// 1: 集中できなかった、5: 非常に集中できた
    var focusLevel: Int

    /// 理解度（1-5）
    /// 1: 理解できなかった、5: 完全に理解できた
    var comprehensionLevel: Int

    /// メモ
    var notes: String?

    // MARK: - Time Analysis

    /// 朝活時間帯（5:00-7:00）かどうか
    var isEarlyMorning: Bool

    /// 朝の時間帯（5:00-9:00）かどうか
    var isMorningSession: Bool

    /// セッション開始時刻（時）
    var startHour: Int

    // MARK: - Session Status

    var isCompleted: Bool
    var wasInterrupted: Bool

    // MARK: - Computed Properties

    /// セッションの品質スコア（SM-2用、0-5）
    var qualityScore: Int {
        // 集中度と理解度の平均を0-5スケールに
        let average = Double(focusLevel + comprehensionLevel) / 2.0
        return max(0, min(5, Int(average)))
    }

    /// セッション効率（実際時間/予定時間）
    var efficiency: Double {
        guard plannedMinutes > 0 else { return 0 }
        return Double(actualMinutes) / Double(plannedMinutes)
    }

    /// 朝活ボーナススコア（0.0-0.3）
    var morningBonus: Double {
        if isEarlyMorning { return 0.3 }
        if isMorningSession { return 0.15 }
        return 0.0
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        studyItemId: UUID,
        plannedMinutes: Int = 25,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.studyItemId = studyItemId
        self.plannedMinutes = plannedMinutes
        self.startedAt = startedAt
        self.endedAt = nil

        self.actualMinutes = 0
        self.focusLevel = 3
        self.comprehensionLevel = 3
        self.notes = nil

        // 時間帯分析
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startedAt)
        self.startHour = hour
        self.isEarlyMorning = hour >= 5 && hour < 7
        self.isMorningSession = hour >= 5 && hour < 9

        self.isCompleted = false
        self.wasInterrupted = false
    }

    // MARK: - Methods

    /// セッション完了
    func complete(focusLevel: Int, comprehensionLevel: Int, notes: String? = nil) {
        self.endedAt = Date()
        self.focusLevel = max(1, min(5, focusLevel))
        self.comprehensionLevel = max(1, min(5, comprehensionLevel))
        self.notes = notes
        self.isCompleted = true

        // 実際の学習時間を計算
        if let ended = endedAt {
            self.actualMinutes = Int(ended.timeIntervalSince(startedAt) / 60)
        }
    }

    /// セッション中断
    func interrupt() {
        self.endedAt = Date()
        self.wasInterrupted = true
        self.isCompleted = false

        if let ended = endedAt {
            self.actualMinutes = Int(ended.timeIntervalSince(startedAt) / 60)
        }
    }
}

// MARK: - StudySession Statistics Extension

extension StudySession {
    /// セッションの総合スコア（分析用）
    var overallScore: Double {
        let baseScore = Double(qualityScore) / 5.0
        let efficiencyBonus = min(efficiency, 1.2) * 0.1
        return min(baseScore + efficiencyBonus + morningBonus, 1.0)
    }
}
