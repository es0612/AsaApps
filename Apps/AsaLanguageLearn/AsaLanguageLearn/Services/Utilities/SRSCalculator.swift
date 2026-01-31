//
//  SRSCalculator.swift
//  AsaLanguageLearn
//
//  間隔反復学習（SRS）の計算ユーティリティ
//

import Foundation

/// 間隔反復学習（SRS）の計算ユーティリティ
/// SM-2アルゴリズムの簡易版を実装
enum SRSCalculator {
    // MARK: - Interval Calculation

    /// 次回復習までの間隔（日数）を計算
    /// - Parameter streak: 連続正解数
    /// - Returns: 次回復習までの日数
    static func calculateInterval(streak: Int) -> Int {
        switch streak {
        case 0: return 0        // 未学習または不正解後
        case 1: return 1        // 1日後
        case 2: return 3        // 3日後
        case 3: return 7        // 1週間後
        case 4: return 14       // 2週間後
        case 5: return 30       // 1ヶ月後
        default: return min(90, streak * 15)  // 最大3ヶ月
        }
    }

    /// 次回復習日を計算
    /// - Parameters:
    ///   - streak: 連続正解数
    ///   - from: 基準日（デフォルト: 今日）
    /// - Returns: 次回復習日
    static func calculateNextReviewDate(streak: Int, from: Date = Date()) -> Date {
        let interval = calculateInterval(streak: streak)
        return Calendar.current.date(byAdding: .day, value: interval, to: from) ?? from
    }

    // MARK: - Mastery Level

    /// 連続正解数から習熟レベルを判定
    /// - Parameter streak: 連続正解数
    /// - Returns: 習熟レベル
    static func calculateMasteryLevel(streak: Int) -> MasteryLevel {
        MasteryLevel.from(streak: streak)
    }

    // MARK: - Review Priority

    /// 復習の優先度を計算
    /// 優先度が高いほど早く復習すべき
    /// - Parameters:
    ///   - nextReviewDate: 次回復習予定日
    ///   - correctRate: 正解率
    /// - Returns: 優先度（0.0〜1.0、高いほど優先）
    static func calculateReviewPriority(
        nextReviewDate: Date?,
        correctRate: Double
    ) -> Double {
        guard let nextReview = nextReviewDate else {
            return 1.0  // 復習日未設定は最優先
        }

        let now = Date()
        let daysOverdue = Calendar.current.dateComponents(
            [.day],
            from: nextReview,
            to: now
        ).day ?? 0

        // 期限切れの度合いに応じた優先度
        var priority: Double
        if daysOverdue > 0 {
            // 期限超過: 超過日数に応じて優先度上昇
            priority = min(1.0, Double(daysOverdue) / 7.0)
        } else {
            // 期限前: まだ復習不要
            priority = 0.0
        }

        // 正解率が低いほど優先度を上げる
        let correctRateFactor = 1.0 - correctRate
        priority = priority * 0.7 + correctRateFactor * 0.3

        return priority
    }

    // MARK: - Statistics

    /// 今日復習すべきアイテム数を計算
    /// - Parameter items: 学習アイテムのリスト
    /// - Returns: 今日復習すべきアイテム数
    static func countDueForReview<T: HasLearningProgress>(_ items: [T]) -> Int {
        items.filter { item in
            guard let progress = item.learningProgress else { return false }
            return progress.needsReview
        }.count
    }

    /// 習熟レベル別のアイテム数を計算
    /// - Parameter items: 学習アイテムのリスト
    /// - Returns: レベル別のカウント
    static func countByMasteryLevel<T: HasLearningProgress>(
        _ items: [T]
    ) -> [MasteryLevel: Int] {
        var counts: [MasteryLevel: Int] = [:]
        for level in MasteryLevel.allCases {
            counts[level] = 0
        }

        for item in items {
            let level = item.learningProgress?.masteryLevel ?? .new
            counts[level, default: 0] += 1
        }

        return counts
    }

    /// 復習効率（習得率）を計算
    /// - Parameter items: 学習アイテムのリスト
    /// - Returns: 習得率（0.0〜1.0）
    static func calculateMasteryRate<T: HasLearningProgress>(_ items: [T]) -> Double {
        guard !items.isEmpty else { return 0.0 }

        let masteredCount = items.filter { item in
            item.learningProgress?.masteryLevel == .mastered
        }.count

        return Double(masteredCount) / Double(items.count)
    }
}

// MARK: - Protocol for Items with Progress

/// 学習進捗を持つアイテムのプロトコル
protocol HasLearningProgress {
    var learningProgress: LearningProgress? { get }
}

// MARK: - LearningItem Extension

extension LearningItem: HasLearningProgress {
    var learningProgress: LearningProgress? {
        progress
    }
}
