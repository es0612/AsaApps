import Foundation
import SwiftData
import Testing

@testable import AsaPhotoStoryKit

// MARK: - モック DataService

/// テスト用のモックデータサービス
@MainActor
final class MockStoryDataService: StoryDataServiceProtocol {
    var stories: [PhotoStory] = []
    var shouldThrowError = false

    func fetchStories(searchText: String?, filterFavorites: Bool) throws -> [PhotoStory] {
        if shouldThrowError { throw PhotoStoryError.storyNotFound }

        var result = stories

        if filterFavorites {
            result = result.filter(\.isFavorite)
        }

        if let searchText, !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    func createStory(title: String, template: StoryTemplate, theme: StoryTheme) throws -> PhotoStory {
        if shouldThrowError { throw PhotoStoryError.dataCorruption }
        let story = PhotoStory(title: title, template: template, theme: theme)
        // テンプレートに応じたページ追加
        for i in 0 ..< template.defaultPageCount {
            let page = StoryPage(order: i)
            story.pages.append(page)
        }
        stories.append(story)
        return story
    }

    func deleteStory(_ story: PhotoStory) throws {
        if shouldThrowError { throw PhotoStoryError.storyNotFound }
        stories.removeAll { $0.id == story.id }
    }

    func updateStory(_ story: PhotoStory) throws {
        if shouldThrowError { throw PhotoStoryError.dataCorruption }
        story.updatedAt = Date()
    }

    func addPage(to story: PhotoStory, layout: PageLayout) throws -> StoryPage {
        if shouldThrowError { throw PhotoStoryError.pageNotFound }
        let nextOrder = story.pages.map(\.order).max().map { $0 + 1 } ?? 0
        let page = StoryPage(order: nextOrder, layout: layout)
        story.pages.append(page)
        return page
    }

    func removePage(_ page: StoryPage, from story: PhotoStory) throws {
        if shouldThrowError { throw PhotoStoryError.pageNotFound }
        story.pages.removeAll { $0.id == page.id }
        for (index, existingPage) in story.pages.sorted(by: { $0.order < $1.order }).enumerated() {
            existingPage.order = index
        }
    }

    func reorderPages(in story: PhotoStory, fromIndex: Int, toIndex: Int) throws {
        if shouldThrowError { throw PhotoStoryError.pageNotFound }
        var sorted = story.pages.sorted { $0.order < $1.order }
        guard fromIndex >= 0, fromIndex < sorted.count,
              toIndex >= 0, toIndex < sorted.count else {
            throw PhotoStoryError.pageNotFound
        }
        let movedPage = sorted.remove(at: fromIndex)
        sorted.insert(movedPage, at: toIndex)
        for (index, page) in sorted.enumerated() {
            page.order = index
        }
    }
}

// MARK: - StoryListViewModel テスト

@Suite("StoryListViewModel テスト")
@MainActor
struct StoryListViewModelTests {
    @Test("StoryListViewModel fetchStories 初期状態 - 空のストーリーリスト")
    func testFetchStoriesInitialState() {
        let mockService = MockStoryDataService()
        let viewModel = StoryListViewModel(dataService: mockService)

        #expect(viewModel.stories.isEmpty)
        #expect(viewModel.searchText == "")
        #expect(viewModel.filterFavorites == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)

        viewModel.fetchStories()
        #expect(viewModel.stories.isEmpty)
    }

    @Test("StoryListViewModel searchText フィルタリング")
    func testSearchTextFiltering() {
        let mockService = MockStoryDataService()
        mockService.stories = [
            PhotoStory(title: "家族旅行"),
            PhotoStory(title: "誕生日パーティー"),
            PhotoStory(title: "夏休みの旅行"),
        ]

        let viewModel = StoryListViewModel(dataService: mockService)

        // 全件取得
        viewModel.fetchStories()
        #expect(viewModel.stories.count == 3)

        // 検索フィルタ
        viewModel.searchText = "旅行"
        viewModel.fetchStories()
        #expect(viewModel.stories.count == 2)

        // 該当なし
        viewModel.searchText = "クリスマス"
        viewModel.fetchStories()
        #expect(viewModel.stories.isEmpty)
    }

    @Test("StoryListViewModel filterFavorites - お気に入りフィルター")
    func testFilterFavorites() {
        let mockService = MockStoryDataService()
        let favoriteStory = PhotoStory(title: "お気に入りストーリー", isFavorite: true)
        let normalStory = PhotoStory(title: "通常のストーリー", isFavorite: false)
        mockService.stories = [favoriteStory, normalStory]

        let viewModel = StoryListViewModel(dataService: mockService)

        // お気に入りフィルタOFF
        viewModel.fetchStories()
        #expect(viewModel.stories.count == 2)

        // お気に入りフィルタON
        viewModel.filterFavorites = true
        viewModel.fetchStories()
        #expect(viewModel.stories.count == 1)
        #expect(viewModel.stories.first?.title == "お気に入りストーリー")
    }
}

// MARK: - StoryEditorViewModel テスト

@Suite("StoryEditorViewModel テスト")
@MainActor
struct StoryEditorViewModelTests {
    @Test("StoryEditorViewModel currentPage 取得 - ページ存在時")
    func testCurrentPageRetrieval() {
        let mockService = MockStoryDataService()
        let story = PhotoStory(title: "テストストーリー")
        let page0 = StoryPage(order: 0, layout: .singlePhoto)
        let page1 = StoryPage(order: 1, layout: .twoHorizontal)
        story.pages = [page0, page1]

        let viewModel = StoryEditorViewModel(story: story, dataService: mockService)

        // 最初のページ
        #expect(viewModel.currentPage?.id == page0.id)
        #expect(viewModel.currentPageIndex == 0)

        // 2番目のページに移動
        viewModel.currentPageIndex = 1
        #expect(viewModel.currentPage?.id == page1.id)
    }

    @Test("StoryEditorViewModel canUndo/canRedo 初期状態 - 両方false")
    func testCanUndoRedoInitialState() {
        let mockService = MockStoryDataService()
        let story = PhotoStory(title: "テスト")

        let viewModel = StoryEditorViewModel(story: story, dataService: mockService)

        #expect(viewModel.canUndo == false)
        #expect(viewModel.canRedo == false)
        #expect(viewModel.isModified == false)
    }
}

// MARK: - PageCanvasViewModel テスト

@Suite("PageCanvasViewModel テスト")
@MainActor
struct PageCanvasViewModelTests {
    @Test("PageCanvasViewModel elements - zOrderでソート済み")
    func testElementsSortedByZOrder() {
        let page = StoryPage()
        let element1 = StoryElement(type: .photo, zOrder: 2)
        let element2 = StoryElement(type: .text, zOrder: 0)
        let element3 = StoryElement(type: .sticker, zOrder: 1)
        page.elements = [element1, element2, element3]

        let viewModel = PageCanvasViewModel(page: page)
        let elements = viewModel.elements

        #expect(elements.count == 3)
        #expect(elements[0].zOrder == 0)
        #expect(elements[1].zOrder == 1)
        #expect(elements[2].zOrder == 2)
    }

    @Test("PageCanvasViewModel selectedElementId 管理 - 選択と解除")
    func testSelectedElementIdManagement() {
        let page = StoryPage()
        let viewModel = PageCanvasViewModel(page: page)

        // 初期状態: 選択なし
        #expect(viewModel.selectedElementId == nil)
        #expect(viewModel.selectedElement == nil)

        // テキスト要素を追加 → 自動選択
        viewModel.addTextElement()
        #expect(viewModel.selectedElementId != nil)
        #expect(viewModel.selectedElement != nil)
        #expect(viewModel.selectedElement?.elementType == .text)

        let selectedId = viewModel.selectedElementId!

        // 選択解除
        viewModel.deselectAll()
        #expect(viewModel.selectedElementId == nil)

        // 要素を削除すると選択も解除
        viewModel.selectedElementId = selectedId
        viewModel.deleteElement(id: selectedId)
        #expect(viewModel.selectedElementId == nil)
        #expect(page.elements.isEmpty)
    }
}

// MARK: - StoryPreviewViewModel テスト

@Suite("StoryPreviewViewModel テスト")
@MainActor
struct StoryPreviewViewModelTests {
    @Test("StoryPreviewViewModel play/pause 状態管理")
    func testPlayPauseStateManagement() {
        let story = PhotoStory(title: "プレビューテスト")
        let page0 = StoryPage(order: 0, duration: 2.0)
        let page1 = StoryPage(order: 1, duration: 3.0)
        let page2 = StoryPage(order: 2, duration: 2.5)
        story.pages = [page0, page1, page2]

        let viewModel = StoryPreviewViewModel(story: story)

        // 初期状態
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.progress == 0)
        #expect(viewModel.pageCount == 3)
        #expect(viewModel.isLastPage == false)

        // 再生開始
        viewModel.play()
        #expect(viewModel.isPlaying == true)

        // 一時停止
        viewModel.pause()
        #expect(viewModel.isPlaying == false)

        // ページ移動
        viewModel.nextPage()
        #expect(viewModel.currentPageIndex == 1)

        viewModel.nextPage()
        #expect(viewModel.currentPageIndex == 2)
        #expect(viewModel.isLastPage == true)

        // 前のページ
        viewModel.previousPage()
        #expect(viewModel.currentPageIndex == 1)

        // 指定ページへ移動
        viewModel.goToPage(0)
        #expect(viewModel.currentPageIndex == 0)

        // 範囲外のページへの移動は無視
        viewModel.goToPage(10)
        #expect(viewModel.currentPageIndex == 0)
        viewModel.goToPage(-1)
        #expect(viewModel.currentPageIndex == 0)

        // リセット
        viewModel.goToPage(2)
        viewModel.reset()
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.progress == 0)
    }
}
