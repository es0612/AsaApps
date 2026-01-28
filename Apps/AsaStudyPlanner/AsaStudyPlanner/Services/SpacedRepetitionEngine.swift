import Foundation

/// 間隔反復学習エンジン（SM-2アルゴリズム）
/// 復習タイミングを最適化して長期記憶への定着を促進
final class SpacedRepetitionEngine: Sendable {

    // MARK: - SM-2 Constants

    /// 最小EaseFactor（これ以下にはならない）
    static let minimumEaseFactor: Double = 1.3

    /// 初期EaseFactor
    static let initialEaseFactor: Double = 2.5

    /// 最大EaseFactor
    static let maximumEaseFactor: Double = 3.0

    // MARK: - Review Quality

    /// 復習の品質評価（0-5）
    /// SM-2アルゴリズムの標準的な評価基準
    enum ReviewQuality: Int, Sendable {
        case completeBlackout = 0       // 完全に忘れた
        case incorrectButRemembered = 1 // 不正解だが見れば思い出した
        case incorrectEasyRecall = 2    // 不正解だが思い出しやすかった
        case correctDifficult = 3       // 正解だが難しかった
        case correctHesitation = 4      // 正解、少し迷った
        case perfectRecall = 5          // 完璧に思い出せた

        /// 成功とみなすか（3以上）
        var isSuccessful: Bool {
            rawValue >= 3
        }

        /// セッションの集中度・理解度から品質を推定
        static func from(focusLevel: Int, comprehensionLevel: Int) -> ReviewQuality {
            let average = (focusLevel + comprehensionLevel) / 2
            switch average {
            case 5: return .perfectRecall
            case 4: return .correctHesitation
            case 3: return .correctDifficult
            case 2: return .incorrectEasyRecall
            case 1: return .incorrectButRemembered
            default: return .completeBlackout
            }
        }
    }

    // MARK: - SM-2 Calculation

    /// SM-2アルゴリズムで次回復習日を計算
    /// - Parameters:
    ///   - quality: 復習の品質（0-5）
    ///   - repetitionCount: 連続正解回数
    ///   - easeFactor: 現在のEaseFactor
    ///   - lastInterval: 前回の復習間隔（日数）
    /// - Returns: 次回の復習パラメータ
    func calculateNextReview(
        quality: ReviewQuality,
        repetitionCount: Int,
        easeFactor: Double,
        lastInterval: Int
    ) -> SM2Result {
        let q = Double(quality.rawValue)

        // EaseFactorの更新
        // EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
        var newEaseFactor = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        newEaseFactor = max(Self.minimumEaseFactor, min(Self.maximumEaseFactor, newEaseFactor))

        // 復習が成功した場合
        if quality.isSuccessful {
            let newRepetitionCount = repetitionCount + 1
            let newInterval: Int

            switch newRepetitionCount {
            case 1:
                newInterval = 1  // 初回成功: 1日後
            case 2:
                newInterval = 6  // 2回目成功: 6日後
            default:
                // n回目成功: 前回間隔 × EaseFactor
                newInterval = Int(Double(lastInterval) * newEaseFactor)
            }

            return SM2Result(
                nextInterval: newInterval,
                newEaseFactor: newEaseFactor,
                newRepetitionCount: newRepetitionCount,
                wasSuccessful: true
            )
        } else {
            // 復習に失敗した場合: リセット
            return SM2Result(
                nextInterval: 1,  // 翌日に再復習
                newEaseFactor: newEaseFactor,
                newRepetitionCount: 0,  // リセット
                wasSuccessful: false
            )
        }
    }

    /// 学習項目の復習パラメータを更新
    func updateItemAfterReview(
        item: StudyItem,
        quality: ReviewQuality
    ) {
        let result = calculateNextReview(
            quality: quality,
            repetitionCount: item.repetitionCount,
            easeFactor: item.easeFactor,
            lastInterval: item.lastIntervalDays
        )

        item.easeFactor = result.newEaseFactor
        item.repetitionCount = result.newRepetitionCount
        item.lastIntervalDays = result.nextInterval
        item.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: result.nextInterval,
            to: Date()
        )
        item.updatedAt = Date()
    }

    /// セッション完了時に復習パラメータを更新
    func updateItemAfterSession(
        item: StudyItem,
        session: StudySession
    ) {
        guard session.isCompleted else { return }

        let quality = ReviewQuality.from(
            focusLevel: session.focusLevel,
            comprehensionLevel: session.comprehensionLevel
        )

        updateItemAfterReview(item: item, quality: quality)
    }

    // MARK: - Review Scheduling

    /// 今日復習が必要な項目をフィルタ
    func filterItemsNeedingReview(_ items: [StudyItem]) -> [StudyItem] {
        let today = Calendar.current.startOfDay(for: Date())

        return items.filter { item in
            guard let nextReview = item.nextReviewDate else {
                // 復習スケジュールなし = 一度も学習していない
                return item.sessionCount > 0  // 学習済みなら復習対象
            }

            return nextReview <= today
        }
    }

    /// 復習の緊急度でソート
    func sortByReviewUrgency(_ items: [StudyItem]) -> [StudyItem] {
        items.sorted { item1, item2 in
            guard let date1 = item1.nextReviewDate else { return false }
            guard let date2 = item2.nextReviewDate else { return true }
            return date1 < date2  // 早い日付が優先
        }
    }

    // MARK: - Statistics

    /// 復習統計を計算
    func calculateReviewStats(for items: [StudyItem]) -> ReviewStatistics {
        let needsReviewToday = filterItemsNeedingReview(items).count
        let totalWithSchedule = items.filter { $0.nextReviewDate != nil }.count
        let averageEaseFactor = items.isEmpty ? Self.initialEaseFactor :
            items.reduce(0.0) { $0 + $1.easeFactor } / Double(items.count)

        return ReviewStatistics(
            itemsNeedingReviewToday: needsReviewToday,
            totalItemsWithSchedule: totalWithSchedule,
            averageEaseFactor: averageEaseFactor
        )
    }
}

// MARK: - SM2 Result

/// SM-2アルゴリズムの計算結果
struct SM2Result: Sendable {
    /// 次回復習までの日数
    let nextInterval: Int

    /// 更新されたEaseFactor
    let newEaseFactor: Double

    /// 更新された連続正解回数
    let newRepetitionCount: Int

    /// 復習が成功したか
    let wasSuccessful: Bool
}

// MARK: - Review Statistics

/// 復習統計
struct ReviewStatistics: Sendable {
    /// 今日復習が必要な項目数
    let itemsNeedingReviewToday: Int

    /// 復習スケジュールがある項目数
    let totalItemsWithSchedule: Int

    /// 平均EaseFactor
    let averageEaseFactor: Double

    /// 復習の健全性スコア（0.0-1.0）
    var healthScore: Double {
        guard totalItemsWithSchedule > 0 else { return 1.0 }
        let overdueRatio = Double(itemsNeedingReviewToday) / Double(totalItemsWithSchedule)
        return max(0.0, 1.0 - overdueRatio)
    }
}
