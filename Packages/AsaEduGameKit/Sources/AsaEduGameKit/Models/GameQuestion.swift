import Foundation

// MARK: - ゲーム問題

/// 1問分の問題データ（非永続化、実行時生成）
public struct GameQuestion: Identifiable, Sendable, Equatable {
    public var id: UUID = UUID()

    /// 問題タイプ
    public let questionType: QuestionType

    /// 問題文（例: "3 + 2 = ?"、"「あ」はどれ？"）
    public let questionText: String

    /// 選択肢（タップ選択式の場合）
    public let options: [String]

    /// 正解
    public let correctAnswer: String

    /// 補助画像名（図形問題等で使用）
    public let imageName: String?

    /// ヒント（子供向け応援メッセージ）
    public let hint: String?

    public init(
        questionType: QuestionType,
        questionText: String,
        options: [String],
        correctAnswer: String,
        imageName: String? = nil,
        hint: String? = nil
    ) {
        self.questionType = questionType
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.imageName = imageName
        self.hint = hint
    }
}
