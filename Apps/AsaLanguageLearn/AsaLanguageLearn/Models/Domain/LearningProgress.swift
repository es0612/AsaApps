//
//  LearningProgress.swift
//  AsaLanguageLearn
//
//  学習進捗（SRS間隔反復学習データ）
//

import Foundation
import SwiftData

/// 学習進捗
/// SM-2アルゴリズム簡易版に基づく間隔反復学習データ
@Model
final class LearningProgress {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID

    /// 正解数
    var correctCount: Int

    /// 総回答数
    var totalCount: Int

    /// 連続正解数（SRSのキー指標）
    var streak: Int

    /// 最高連続正解数
    var bestStreak: Int

    /// 累計練習時間（秒）
    var totalPracticeSeconds: Int

    /// 最終学習日時
    var lastStudiedAt: Date?

    /// 次回復習予定日
    var nextReviewDate: Date?

    /// 学習済みフラグ
    var isStudied: Bool

    /// 最後の発音スコア
    var lastPronunciationScore: Double?

    /// 平均発音スコア
    var averagePronunciationScore: Double

    /// 作成日時
    var createdAt: Date

    var item: LearningItem?

    // MARK: - Computed Properties

    /// 正解率（0.0〜1.0）
    var correctRate: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(correctCount) / Double(totalCount)
    }

    /// 習熟レベル
    var masteryLevel: MasteryLevel {
        MasteryLevel.from(streak: streak)
    }

    /// 復習が必要か
    var needsReview: Bool {
        guard isStudied else { return true }
        guard let nextReviewDate = nextReviewDate else { return true }
        return Date() >= nextReviewDate
    }

    /// 次回復習までの日数
    var daysUntilReview: Int? {
        guard let nextReviewDate = nextReviewDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextReviewDate)
        return max(0, components.day ?? 0)
    }

    /// 復習ステータスのテキスト
    var reviewStatusText: String {
        if !isStudied {
            return "未学習"
        }
        guard let days = daysUntilReview else {
            return "復習対象"
        }
        if days == 0 {
            return "今日復習"
        } else if days == 1 {
            return "明日復習"
        } else {
            return "\(days)日後に復習"
        }
    }

    // MARK: - Initialization

    init(id: UUID = UUID()) {
        self.id = id
        self.correctCount = 0
        self.totalCount = 0
        self.streak = 0
        self.bestStreak = 0
        self.totalPracticeSeconds = 0
        self.isStudied = false
        self.averagePronunciationScore = 0.0
        self.createdAt = Date()
    }

    // MARK: - SRS Methods

    /// 正解を記録
    /// - Parameter pronunciationScore: 発音スコア（0.0〜1.0）
    func recordCorrect(pronunciationScore: Double) {
        correctCount += 1
        totalCount += 1
        streak += 1
        bestStreak = max(bestStreak, streak)
        lastStudiedAt = Date()
        isStudied = true
        lastPronunciationScore = pronunciationScore

        // 平均スコアの更新
        updateAverageScore(pronunciationScore)

        // 次回復習日の計算
        let interval = calculateInterval()
        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date())
    }

    /// 不正解を記録
    /// - Parameter pronunciationScore: 発音スコア（0.0〜1.0）
    func recordIncorrect(pronunciationScore: Double) {
        totalCount += 1
        streak = 0  // 連続正解リセット
        lastStudiedAt = Date()
        isStudied = true
        lastPronunciationScore = pronunciationScore

        // 平均スコアの更新
        updateAverageScore(pronunciationScore)

        // 不正解は翌日復習
        nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    }

    /// 練習時間を追加
    func addPracticeTime(seconds: Int) {
        totalPracticeSeconds += seconds
    }

    // MARK: - Private Methods

    /// SM-2アルゴリズム簡易版による復習間隔計算
    /// streak: 1 → 1日, 2 → 3日, 3 → 7日, 4 → 14日, 5 → 30日, 6+ → 最大90日
    private func calculateInterval() -> Int {
        switch streak {
        case 1: return 1
        case 2: return 3
        case 3: return 7
        case 4: return 14
        case 5: return 30
        default: return min(90, streak * 15)
        }
    }

    /// 平均発音スコアの更新
    private func updateAverageScore(_ newScore: Double) {
        if totalCount == 1 {
            averagePronunciationScore = newScore
        } else {
            // 累積移動平均
            averagePronunciationScore = averagePronunciationScore
                + (newScore - averagePronunciationScore) / Double(totalCount)
        }
    }
}

// MARK: - Sample Data

extension LearningProgress {
    static var sampleNew: LearningProgress {
        LearningProgress()
    }

    static var sampleLearning: LearningProgress {
        let progress = LearningProgress()
        progress.correctCount = 2
        progress.totalCount = 3
        progress.streak = 2
        progress.bestStreak = 2
        progress.isStudied = true
        progress.lastStudiedAt = Date().addingTimeInterval(-86400) // 1日前
        progress.nextReviewDate = Date().addingTimeInterval(86400 * 3) // 3日後
        progress.lastPronunciationScore = 0.75
        progress.averagePronunciationScore = 0.72
        return progress
    }

    static var sampleMastered: LearningProgress {
        let progress = LearningProgress()
        progress.correctCount = 10
        progress.totalCount = 11
        progress.streak = 8
        progress.bestStreak = 8
        progress.isStudied = true
        progress.lastStudiedAt = Date().addingTimeInterval(-86400 * 30) // 30日前
        progress.nextReviewDate = Date().addingTimeInterval(86400 * 60) // 60日後
        progress.lastPronunciationScore = 0.95
        progress.averagePronunciationScore = 0.88
        return progress
    }
}
