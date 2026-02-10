import Foundation

// MARK: - 論理ゲームモードViewModel

/// 論理ゲームモード専用のUI状態管理
@Observable
@MainActor
public final class LogicGameViewModel {

    // MARK: - Properties

    /// 問題に表示するアイテムリスト
    public var items: [String] = []

    /// 現在の問題サブタイプ
    public var questionSubtype: QuestionType = .oddOneOut

    /// 選択されたアイテム（なかまはずれ等）
    public var selectedItem: String?

    /// 並べ替え用のアイテムリスト（じゅんばん問題）
    public var orderedItems: [String] = []

    // MARK: - Init

    public init() {}

    // MARK: - Methods

    /// 問題データからUI表示用の状態をセットアップ
    public func setupForQuestion(_ question: GameQuestion) {
        selectedItem = nil
        questionSubtype = question.questionType

        switch question.questionType {
        case .oddOneOut:
            // なかまはずれ: 選択肢からひとつ選ぶ
            items = question.options
            orderedItems = []
        case .sequenceOrder:
            // じゅんばん: アイテムを正しい順序に並べる
            items = question.options
            orderedItems = question.options
        case .patternCompletion:
            // つぎはなに？: パターンの続きを選ぶ
            items = question.options
            orderedItems = []
        default:
            items = question.options
            orderedItems = []
        }
    }

    /// アイテムを並べ替える（じゅんばん問題用）
    /// - Parameters:
    ///   - from: 移動元インデックス
    ///   - to: 移動先インデックス
    public func reorderItem(from: Int, to: Int) {
        guard from >= 0, from < orderedItems.count,
              to >= 0, to < orderedItems.count else {
            return
        }

        let item = orderedItems.remove(at: from)
        orderedItems.insert(item, at: to)
    }
}
