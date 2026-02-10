import Foundation

// MARK: - 難易度調整プロトコル

/// アダプティブ難易度調整サービスのインターフェース
public protocol DifficultyAdjusting: Sendable {
    /// 最近の正答率に基づいて推奨難易度を算出
    func recommendedDifficulty(
        currentDifficulty: DifficultyLevel,
        recentAccuracy: Double,
        consecutiveCorrect: Int,
        consecutiveWrong: Int
    ) -> DifficultyLevel

    /// セッション結果から次回の難易度を提案
    func adjustAfterSession(
        currentDifficulty: DifficultyLevel,
        sessionAccuracy: Double
    ) -> DifficultyLevel
}
