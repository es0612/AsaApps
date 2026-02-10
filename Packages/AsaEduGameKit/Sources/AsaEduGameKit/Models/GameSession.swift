import Foundation
import SwiftData

// MARK: - ゲームセッション

/// 1回のゲームプレイ記録
@Model
public final class GameSession {
    public var id: UUID = UUID()

    /// ゲームモード（rawValue保存）
    public var gameModeRawValue: String = GameMode.mathQuiz.rawValue

    /// 難易度（rawValue保存）
    public var difficultyRawValue: String = DifficultyLevel.easy.rawValue

    /// 出題数
    public var totalQuestions: Int = 0

    /// 正解数
    public var correctAnswers: Int = 0

    /// 獲得した星
    public var earnedStars: Int = 0

    /// 最大コンボ数
    public var maxCombo: Int = 0

    /// プレイ時間（秒）
    public var durationSeconds: Double = 0

    /// 開始日時
    public var startedAt: Date = Date()

    /// 終了日時
    public var endedAt: Date?

    /// 関連する学習記録
    @Relationship(deleteRule: .cascade)
    public var learningRecords: [LearningRecord] = []

    /// 所属プロフィール
    public var profile: UserProfile?

    public init(
        gameMode: GameMode = .mathQuiz,
        difficulty: DifficultyLevel = .easy,
        totalQuestions: Int = 0
    ) {
        self.gameModeRawValue = gameMode.rawValue
        self.difficultyRawValue = difficulty.rawValue
        self.totalQuestions = totalQuestions
    }

    // MARK: - Computed Properties

    /// ゲームモード（enum）
    public var gameMode: GameMode {
        get { GameMode(rawValue: gameModeRawValue) ?? .mathQuiz }
        set { gameModeRawValue = newValue.rawValue }
    }

    /// 難易度（enum）
    public var difficulty: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficultyRawValue) ?? .easy }
        set { difficultyRawValue = newValue.rawValue }
    }

    /// 正答率（0.0〜1.0）
    public var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }

    /// 正答率のパーセンテージ表示
    public var accuracyPercentage: Int {
        Int(accuracy * 100)
    }

    /// パーフェクト（全問正解）かどうか
    public var isPerfect: Bool {
        totalQuestions > 0 && correctAnswers == totalQuestions
    }

    /// セッションを終了する
    public func complete() {
        endedAt = Date()
        if let start = Optional(startedAt), let end = endedAt {
            durationSeconds = end.timeIntervalSince(start)
        }
    }
}
