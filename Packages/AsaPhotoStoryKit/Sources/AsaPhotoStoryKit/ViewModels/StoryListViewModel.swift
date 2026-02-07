import Foundation

// MARK: - StoryListViewModel

/// ストーリー一覧画面のViewModel
/// 検索・フィルタ・CRUD操作を管理
@MainActor
@Observable
public final class StoryListViewModel {
    // MARK: - Properties

    public var stories: [PhotoStory] = []
    public var searchText: String = ""
    public var filterFavorites: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let dataService: StoryDataServiceProtocol

    // MARK: - Init

    public init(dataService: StoryDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Public Methods

    /// ストーリー一覧を取得
    public func fetchStories() {
        isLoading = true
        defer { isLoading = false }

        do {
            stories = try dataService.fetchStories(
                searchText: searchText.isEmpty ? nil : searchText,
                filterFavorites: filterFavorites
            )
        } catch {
            errorMessage = "ストーリーの読み込みに失敗: \(error.localizedDescription)"
        }
    }

    /// 新しいストーリーを作成
    public func createStory(
        title: String,
        template: StoryTemplate,
        theme: StoryTheme
    ) {
        do {
            _ = try dataService.createStory(
                title: title,
                template: template,
                theme: theme
            )
            fetchStories()
        } catch {
            errorMessage = "ストーリーの作成に失敗: \(error.localizedDescription)"
        }
    }

    /// ストーリーを削除
    public func deleteStory(_ story: PhotoStory) {
        do {
            try dataService.deleteStory(story)
            fetchStories()
        } catch {
            errorMessage = "ストーリーの削除に失敗: \(error.localizedDescription)"
        }
    }

    /// お気に入りを切り替え
    public func toggleFavorite(_ story: PhotoStory) {
        story.isFavorite.toggle()
        story.updatedAt = Date()
        do {
            try dataService.updateStory(story)
            fetchStories()
        } catch {
            errorMessage = "お気に入りの変更に失敗: \(error.localizedDescription)"
        }
    }

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }
}
