import Foundation

// MARK: - 図形パズルモードViewModel

/// 図形パズルモード専用のUI状態管理
@Observable
@MainActor
public final class ShapePuzzleViewModel {

    // MARK: - Properties

    /// 現在の対象図形名
    public var currentShapeName: String = ""

    /// 図形の選択肢リスト
    public var shapeOptions: [String] = []

    /// ハイライト中の図形名（タップ時のフィードバック用）
    public var highlightedShape: String?

    // MARK: - Init

    public init() {}

    // MARK: - Methods

    /// 問題データからUI表示用の状態をセットアップ
    public func setupForQuestion(_ question: GameQuestion) {
        highlightedShape = nil

        switch question.questionType {
        case .shapeIdentification:
            // 図形を見て名前を選ぶ
            currentShapeName = question.correctAnswer
            shapeOptions = question.options
        case .shapePattern:
            // パターンの中から正しい図形を選ぶ
            currentShapeName = question.questionText
            shapeOptions = question.options
        case .shapeCombination:
            // 図形の組み合わせから正解を選ぶ
            currentShapeName = question.questionText
            shapeOptions = question.options
        default:
            currentShapeName = question.questionText
            shapeOptions = question.options
        }
    }
}
