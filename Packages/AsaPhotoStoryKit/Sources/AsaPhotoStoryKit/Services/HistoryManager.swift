import Foundation

// MARK: - HistoryManager

/// Undo/Redo履歴を管理するジェネリッククラス
/// 任意の型の状態を保存し、元に戻す/やり直しを提供
@Observable
public final class HistoryManager<State: Equatable & Codable> {
    // MARK: - Properties

    /// 履歴スタック
    private var undoStack: [State] = []

    /// やり直しスタック
    private var redoStack: [State] = []

    /// 最大履歴数
    public let maxHistoryCount: Int

    /// 元に戻せるかどうか
    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// やり直せるかどうか
    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// 現在の履歴数
    public var historyCount: Int {
        undoStack.count
    }

    // MARK: - Initializer

    public init(maxHistoryCount: Int = 20) {
        self.maxHistoryCount = maxHistoryCount
    }

    // MARK: - Public Methods

    /// 状態を記録（新しいアクションの前に呼び出す）
    public func record(_ state: State) {
        // 同じ状態なら記録しない
        if undoStack.last == state { return }

        undoStack.append(state)

        // 最大履歴数を超えたら古いものを削除
        if undoStack.count > maxHistoryCount {
            undoStack.removeFirst()
        }

        // 新しいアクションを記録したらredoスタックをクリア
        redoStack.removeAll()
    }

    /// 元に戻す
    public func undo(currentState: State) -> State? {
        guard let previousState = undoStack.popLast() else { return nil }

        // 現在の状態をredoスタックに保存
        redoStack.append(currentState)

        return previousState
    }

    /// やり直す
    public func redo(currentState: State) -> State? {
        guard let nextState = redoStack.popLast() else { return nil }

        // 現在の状態をundoスタックに保存
        undoStack.append(currentState)

        return nextState
    }

    /// 履歴をクリア
    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// 履歴をリセットして初期状態を設定
    public func reset(with initialState: State) {
        clear()
        undoStack.append(initialState)
    }
}

// MARK: - StoryEditState

/// ストーリー編集状態を表す構造体（履歴管理用）
public struct StoryEditState: Codable, Equatable {
    public var pageOrders: [UUID: Int]
    public var currentPageId: UUID?

    public init(
        pageOrders: [UUID: Int] = [:],
        currentPageId: UUID? = nil
    ) {
        self.pageOrders = pageOrders
        self.currentPageId = currentPageId
    }

    public static let `default` = StoryEditState()
}

// MARK: - StoryHistoryManager

/// ストーリー編集専用の履歴マネージャー
public typealias StoryHistoryManager = HistoryManager<StoryEditState>
