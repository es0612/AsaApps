import Foundation

// MARK: - アダプティブ難易度調整サービス

/// 正答率に基づいて難易度を自動調整するサービス
/// - 正答率90%以上 or 連続5問正解 -> 難易度UP
/// - 正答率40%以下 or 連続3問不正解 -> 難易度DOWN
/// - それ以外 -> 維持
public final class AdaptiveDifficultyService: DifficultyAdjusting {

    // MARK: - 定数

    /// 難易度UPの正答率しきい値
    private static let upgradeAccuracyThreshold: Double = 0.9

    /// 難易度DOWNの正答率しきい値
    private static let downgradeAccuracyThreshold: Double = 0.4

    /// 難易度UPの連続正解数しきい値
    private static let upgradeConsecutiveCorrect: Int = 5

    /// 難易度DOWNの連続不正解数しきい値
    private static let downgradeConsecutiveWrong: Int = 3

    // MARK: - Init

    public init() {}

    // MARK: - DifficultyAdjusting

    /// 最近の正答率に基づいて推奨難易度を算出
    public func recommendedDifficulty(
        currentDifficulty: DifficultyLevel,
        recentAccuracy: Double,
        consecutiveCorrect: Int,
        consecutiveWrong: Int
    ) -> DifficultyLevel {
        // 難易度UPの判定
        if recentAccuracy >= Self.upgradeAccuracyThreshold
            || consecutiveCorrect >= Self.upgradeConsecutiveCorrect {
            return upgrade(from: currentDifficulty)
        }

        // 難易度DOWNの判定
        if recentAccuracy <= Self.downgradeAccuracyThreshold
            || consecutiveWrong >= Self.downgradeConsecutiveWrong {
            return downgrade(from: currentDifficulty)
        }

        // 維持
        return currentDifficulty
    }

    /// セッション結果から次回の難易度を提案
    public func adjustAfterSession(
        currentDifficulty: DifficultyLevel,
        sessionAccuracy: Double
    ) -> DifficultyLevel {
        if sessionAccuracy >= Self.upgradeAccuracyThreshold {
            return upgrade(from: currentDifficulty)
        }

        if sessionAccuracy <= Self.downgradeAccuracyThreshold {
            return downgrade(from: currentDifficulty)
        }

        return currentDifficulty
    }

    // MARK: - ヘルパー

    /// 1段階難易度を上げる（上限あり）
    private func upgrade(from difficulty: DifficultyLevel) -> DifficultyLevel {
        switch difficulty {
        case .easy: return .normal
        case .normal: return .hard
        case .hard: return .hard
        }
    }

    /// 1段階難易度を下げる（下限あり）
    private func downgrade(from difficulty: DifficultyLevel) -> DifficultyLevel {
        switch difficulty {
        case .easy: return .easy
        case .normal: return .easy
        case .hard: return .normal
        }
    }
}
