import Foundation

/// 学習項目から特徴量を抽出するサービス
/// AI最適化エンジンで使用するスコア計算を担当
final class LearningFeatureExtractor: Sendable {

    // MARK: - Feature Extraction

    /// 学習項目から全特徴量を抽出
    func extractFeatures(from item: StudyItem, at currentTime: Date = Date()) -> LearningFeatures {
        let hour = Calendar.current.component(.hour, from: currentTime)

        return LearningFeatures(
            targetDateScore: calculateTargetDateScore(item.daysUntilTarget),
            difficultyTimeScore: calculateDifficultyTimeScore(
                difficulty: item.difficulty,
                hour: hour
            ),
            masteryScore: calculateMasteryScore(item.masteryLevel),
            reviewScore: calculateReviewScore(item),
            timeOfDayScore: calculateTimeOfDayScore(hour: hour),
            prerequisiteScore: calculatePrerequisiteScore(item),
            categoryImportance: item.category.baseImportanceScore,
            estimatedMinutes: item.estimatedMinutes,
            createdHour: Calendar.current.component(.hour, from: item.createdAt)
        )
    }

    // MARK: - Target Date Score (0.0-1.0)

    /// 目標期限スコア計算
    /// 期限が近いほど高スコア、期限切れは最高スコア
    func calculateTargetDateScore(_ daysUntilTarget: Int?) -> Double {
        guard let days = daysUntilTarget else {
            return 0.3  // 期限なし
        }

        switch days {
        case ...(-1):       // 期限切れ
            return 1.0
        case 0:             // 今日が期限
            return 0.95
        case 1:             // 明日
            return 0.9
        case 2...3:         // 2-3日後
            return 0.7
        case 4...7:         // 1週間以内
            return 0.5
        case 8...14:        // 2週間以内
            return 0.4
        case 15...30:       // 1ヶ月以内
            return 0.35
        default:            // それ以上
            return 0.3
        }
    }

    // MARK: - Difficulty × Time Score (0.0-1.0)

    /// 難易度と時間帯の組み合わせスコア
    /// 難しい内容は朝が最適、簡単な内容は時間帯を選ばない
    func calculateDifficultyTimeScore(difficulty: DifficultyLevel, hour: Int) -> Double {
        let timeScore = calculateTimeOfDayScore(hour: hour)
        let concentrationRequired = difficulty.concentrationRequirement

        // 朝活時間帯（5-9時）は難しい内容にボーナス
        let isOptimalTime = hour >= 5 && hour < 9

        if isOptimalTime {
            // 朝の時間帯: 難易度が高いほどボーナス
            return min(timeScore + difficulty.morningBonus, 1.0)
        } else if hour >= 21 || hour < 5 {
            // 夜間・深夜: 難易度が高いほどペナルティ
            return max(timeScore * (1.0 - difficulty.eveningPenalty), 0.0)
        } else {
            // それ以外の時間帯: 通常スコア
            return timeScore * (1.0 - concentrationRequired * 0.2)
        }
    }

    // MARK: - Mastery Score (0.0-1.0)

    /// 習熟度スコア計算
    /// 習熟度が低いほど高スコア（優先的に学習すべき）
    func calculateMasteryScore(_ masteryLevel: Double) -> Double {
        // 習熟度が低いほど高スコア
        // 0.0 (未学習) -> 1.0
        // 1.0 (マスター) -> 0.0
        return 1.0 - masteryLevel
    }

    // MARK: - Review Score (0.0-1.0)

    /// 復習必要度スコア計算
    /// 復習が必要な項目は高スコア
    func calculateReviewScore(_ item: StudyItem) -> Double {
        guard let nextReview = item.nextReviewDate else {
            // 復習スケジュールなし = まだ学習していない
            return item.sessionCount == 0 ? 0.5 : 0.3
        }

        let now = Date()
        let daysDifference = Calendar.current.dateComponents([.day], from: now, to: nextReview).day ?? 0

        switch daysDifference {
        case ...(-3):       // 3日以上過ぎている
            return 1.0
        case -2...(-1):     // 1-2日過ぎている
            return 0.9
        case 0:             // 今日が復習日
            return 0.85
        case 1:             // 明日
            return 0.6
        case 2...3:         // 2-3日後
            return 0.4
        default:            // それ以上先
            return 0.2
        }
    }

    // MARK: - Time of Day Score (0.0-1.0)

    /// 時間帯スコア計算
    /// 朝活時間帯（5-7時）は最高スコア
    func calculateTimeOfDayScore(hour: Int) -> Double {
        switch hour {
        case 5..<7:         // 深朝活（5-7時）
            return 0.9
        case 7..<9:         // 朝（7-9時）
            return 0.7
        case 9..<12:        // 午前中（9-12時）
            return 0.6
        case 12..<14:       // 昼（12-14時）
            return 0.4
        case 14..<17:       // 午後（14-17時）
            return 0.5
        case 17..<21:       // 夕方（17-21時）
            return 0.55
        case 21..<24, 0..<5: // 夜間・深夜
            return 0.3
        default:
            return 0.5
        }
    }

    // MARK: - Prerequisite Score (0.0-1.0)

    /// 前提知識スコア計算
    /// 前提知識がない項目は高スコア（すぐに始められる）
    func calculatePrerequisiteScore(_ item: StudyItem) -> Double {
        // 前提知識がない = すぐに学習可能 = 高スコア
        if item.prerequisiteItemIds.isEmpty {
            return 1.0
        }

        // 前提知識がある場合は低スコア
        // （実際には前提知識の習熟度を確認すべきだが、簡略化）
        let prerequisiteCount = item.prerequisiteItemIds.count
        return max(0.3, 1.0 - Double(prerequisiteCount) * 0.2)
    }

    // MARK: - Title Complexity (0.0-1.0)

    /// タイトル複雑度計算（参考情報）
    func calculateTitleComplexity(_ title: String) -> Double {
        guard !title.isEmpty else { return 0.0 }

        let wordCount = title.split(separator: " ").count +
                        title.split(separator: "　").count
        let charCount = title.count

        let wordScore = min(Double(wordCount) / 10.0, 1.0)
        let charScore = min(Double(charCount) / 50.0, 1.0)

        return (wordScore + charScore) / 2.0
    }
}

// MARK: - Learning Features

/// 学習項目の抽出された特徴量
struct LearningFeatures: Sendable, Codable {
    /// 目標期限スコア（0.0-1.0）
    let targetDateScore: Double

    /// 難易度×時間帯スコア（0.0-1.0）
    let difficultyTimeScore: Double

    /// 習熟度スコア（0.0-1.0、低習熟度ほど高スコア）
    let masteryScore: Double

    /// 復習必要度スコア（0.0-1.0）
    let reviewScore: Double

    /// 時間帯適性スコア（0.0-1.0）
    let timeOfDayScore: Double

    /// 前提知識スコア（0.0-1.0）
    let prerequisiteScore: Double

    /// カテゴリ重要度（0.0-1.0）
    let categoryImportance: Double

    /// 推定学習時間（分）
    let estimatedMinutes: Int

    /// 作成時刻（時）
    let createdHour: Int

    /// スコア配列（重み付け計算用）
    var asArray: [Double] {
        [targetDateScore, difficultyTimeScore, masteryScore,
         reviewScore, timeOfDayScore, prerequisiteScore]
    }
}
