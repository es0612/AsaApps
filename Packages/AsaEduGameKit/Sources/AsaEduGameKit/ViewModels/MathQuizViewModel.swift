import Foundation

// MARK: - 算数モードViewModel

/// 算数クイズモード専用のUI状態管理
@Observable
@MainActor
public final class MathQuizViewModel {

    // MARK: - Properties

    /// 現在の数式表示文字列（例: "3 + 2 = ?"）
    public var currentExpression: String = ""

    /// 数値の選択肢リスト
    public var answerOptions: [Int] = []

    /// 現在の演算子タイプ（"+", "-", ">" 等）
    public var operationType: String = "+"

    // MARK: - Init

    public init() {}

    // MARK: - Methods

    /// 問題データからUI表示用の状態をセットアップ
    public func setupForQuestion(_ question: GameQuestion) {
        currentExpression = formatExpression(from: question)

        // 選択肢を数値に変換
        answerOptions = question.options.compactMap { Int($0) }

        // 問題タイプから演算子を判定
        switch question.questionType {
        case .addition:
            operationType = "+"
        case .subtraction:
            operationType = "-"
        case .comparison:
            operationType = ">"
        case .fillInBlank:
            operationType = "?"
        default:
            operationType = "+"
        }
    }

    /// 問題データから表示用の数式文字列を生成
    /// - Parameter question: ゲーム問題データ
    /// - Returns: フォーマットされた数式文字列（例: "3 + 2 = ?"）
    public func formatExpression(from question: GameQuestion) -> String {
        // 問題文がすでにフォーマット済みの場合はそのまま返す
        let text = question.questionText

        switch question.questionType {
        case .addition:
            // "3 + 2 = ?" 形式
            return text
        case .subtraction:
            // "5 - 3 = ?" 形式
            return text
        case .comparison:
            // "どっちがおおきい？ 5 と 3" 形式
            return text
        case .fillInBlank:
            // "3 + ? = 5" 形式
            return text
        default:
            return text
        }
    }
}
