import Foundation

// MARK: - 問題生成プロトコル

/// ゲーム問題を生成するサービスのインターフェース
public protocol QuestionGenerating: Sendable {
    /// 指定モード・難易度で問題セットを生成
    func generateQuestions(
        mode: GameMode,
        difficulty: DifficultyLevel,
        count: Int
    ) -> [GameQuestion]

    /// 単一問題を生成
    func generateQuestion(
        type: QuestionType,
        difficulty: DifficultyLevel
    ) -> GameQuestion
}
