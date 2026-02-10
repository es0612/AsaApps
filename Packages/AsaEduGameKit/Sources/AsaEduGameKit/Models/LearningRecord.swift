import Foundation
import SwiftData

// MARK: - 学習記録

/// 個別の問題回答記録
@Model
public final class LearningRecord {
    public var id: UUID = UUID()

    /// 問題タイプ（rawValue保存）
    public var questionTypeRawValue: String = QuestionType.addition.rawValue

    /// 問題内容
    public var questionContent: String = ""

    /// ユーザーの回答
    public var userAnswer: String = ""

    /// 正解
    public var correctAnswer: String = ""

    /// 正解かどうか
    public var isCorrect: Bool = false

    /// 回答時間（秒）
    public var responseTimeSeconds: Double = 0

    /// 回答日時
    public var answeredAt: Date = Date()

    /// 所属セッション
    public var session: GameSession?

    public init(
        questionType: QuestionType = .addition,
        questionContent: String = "",
        userAnswer: String = "",
        correctAnswer: String = "",
        isCorrect: Bool = false,
        responseTimeSeconds: Double = 0
    ) {
        self.questionTypeRawValue = questionType.rawValue
        self.questionContent = questionContent
        self.userAnswer = userAnswer
        self.correctAnswer = correctAnswer
        self.isCorrect = isCorrect
        self.responseTimeSeconds = responseTimeSeconds
    }

    // MARK: - Computed Properties

    /// 問題タイプ（enum）
    public var questionType: QuestionType {
        get { QuestionType(rawValue: questionTypeRawValue) ?? .addition }
        set { questionTypeRawValue = newValue.rawValue }
    }
}
