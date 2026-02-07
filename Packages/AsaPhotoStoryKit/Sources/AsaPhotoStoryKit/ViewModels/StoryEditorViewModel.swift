import Foundation

// MARK: - StoryEditorViewModel

/// ストーリー編集画面のViewModel
/// ページの追加・削除・並べ替え・undo/redo を管理
@MainActor
@Observable
public final class StoryEditorViewModel {
    // MARK: - Properties

    public var story: PhotoStory
    public var currentPageIndex: Int = 0
    public var isModified: Bool = false
    public var errorMessage: String?

    private let dataService: StoryDataServiceProtocol
    private let historyManager = StoryHistoryManager()

    // MARK: - Computed Properties

    /// 現在のページ
    public var currentPage: StoryPage? {
        let sorted = story.sortedPages
        guard currentPageIndex >= 0, currentPageIndex < sorted.count else { return nil }
        return sorted[currentPageIndex]
    }

    /// ページ数
    public var pageCount: Int {
        story.pageCount
    }

    /// undo可能かどうか
    public var canUndo: Bool {
        historyManager.canUndo
    }

    /// redo可能かどうか
    public var canRedo: Bool {
        historyManager.canRedo
    }

    // MARK: - Init

    public init(story: PhotoStory, dataService: StoryDataServiceProtocol) {
        self.story = story
        self.dataService = dataService
    }

    // MARK: - ページ操作

    /// ページを追加
    public func addPage(layout: PageLayout) {
        recordCurrentState()
        do {
            _ = try dataService.addPage(to: story, layout: layout)
            currentPageIndex = story.pageCount - 1
            isModified = true
        } catch {
            errorMessage = "ページの追加に失敗: \(error.localizedDescription)"
        }
    }

    /// ページを削除
    public func removePage(at index: Int) {
        let sorted = story.sortedPages
        guard index >= 0, index < sorted.count else { return }

        recordCurrentState()
        do {
            try dataService.removePage(sorted[index], from: story)
            if currentPageIndex >= story.pageCount {
                currentPageIndex = max(0, story.pageCount - 1)
            }
            isModified = true
        } catch {
            errorMessage = "ページの削除に失敗: \(error.localizedDescription)"
        }
    }

    /// ページの順番を変更
    public func reorderPages(from sourceIndex: Int, to destinationIndex: Int) {
        recordCurrentState()
        do {
            try dataService.reorderPages(in: story, fromIndex: sourceIndex, toIndex: destinationIndex)
            currentPageIndex = destinationIndex
            isModified = true
        } catch {
            errorMessage = "ページの並べ替えに失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Undo/Redo

    /// 元に戻す
    public func undo() {
        let currentState = createCurrentState()
        if let previousState = historyManager.undo(currentState: currentState) {
            applyState(previousState)
            isModified = true
        }
    }

    /// やり直す
    public func redo() {
        let currentState = createCurrentState()
        if let nextState = historyManager.redo(currentState: currentState) {
            applyState(nextState)
            isModified = true
        }
    }

    // MARK: - 保存

    /// 変更を保存
    public func save() {
        do {
            try dataService.updateStory(story)
            isModified = false
        } catch {
            errorMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func recordCurrentState() {
        let state = createCurrentState()
        historyManager.record(state)
    }

    private func createCurrentState() -> StoryEditState {
        var pageOrders: [UUID: Int] = [:]
        for page in story.pages {
            pageOrders[page.id] = page.order
        }
        return StoryEditState(
            pageOrders: pageOrders,
            currentPageId: currentPage?.id
        )
    }

    private func applyState(_ state: StoryEditState) {
        for page in story.pages {
            if let order = state.pageOrders[page.id] {
                page.order = order
            }
        }
        if let pageId = state.currentPageId,
           let index = story.sortedPages.firstIndex(where: { $0.id == pageId }) {
            currentPageIndex = index
        }
    }
}
