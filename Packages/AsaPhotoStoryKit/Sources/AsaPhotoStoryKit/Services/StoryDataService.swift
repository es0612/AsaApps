import Foundation
import SwiftData

// MARK: - StoryDataService

/// SwiftDataベースのCRUD操作を提供するサービス
/// テスト時は inMemory: true で分離した環境を使用
@MainActor
public final class StoryDataService: StoryDataServiceProtocol {
    // MARK: - Properties

    public let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Init

    public init(inMemory: Bool = false) {
        let schema = Schema([
            PhotoStory.self,
            StoryPage.self,
            StoryElement.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("ModelContainerの初期化に失敗: \(error)")
        }
        modelContext = modelContainer.mainContext
    }

    // MARK: - ストーリー操作

    /// ストーリー一覧を取得（検索・フィルタ対応）
    public func fetchStories(searchText: String? = nil, filterFavorites: Bool = false) throws -> [PhotoStory] {
        var descriptor = FetchDescriptor<PhotoStory>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        if filterFavorites {
            descriptor.predicate = #Predicate<PhotoStory> { $0.isFavorite }
        }

        var stories = try modelContext.fetch(descriptor)

        // テキスト検索フィルタ
        if let searchText, !searchText.isEmpty {
            stories = stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                (story.storyDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return stories
    }

    /// ストーリーを作成
    public func createStory(
        title: String,
        template: StoryTemplate,
        theme: StoryTheme
    ) throws -> PhotoStory {
        let story = PhotoStory(
            title: title,
            template: template,
            theme: theme
        )

        // テンプレートに応じたデフォルトページを追加
        for i in 0 ..< template.defaultPageCount {
            let page = StoryPage(order: i)
            page.story = story
            story.pages.append(page)
        }

        modelContext.insert(story)
        try modelContext.save()
        return story
    }

    /// ストーリーを削除
    public func deleteStory(_ story: PhotoStory) throws {
        modelContext.delete(story)
        try modelContext.save()
    }

    /// ストーリーを更新（変更を保存）
    public func updateStory(_ story: PhotoStory) throws {
        story.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - ページ操作

    /// ページを追加
    public func addPage(to story: PhotoStory, layout: PageLayout) throws -> StoryPage {
        let nextOrder = story.pages.map(\.order).max().map { $0 + 1 } ?? 0
        let page = StoryPage(order: nextOrder, layout: layout)
        page.story = story
        story.pages.append(page)
        story.updatedAt = Date()
        try modelContext.save()
        return page
    }

    /// ページを削除
    public func removePage(_ page: StoryPage, from story: PhotoStory) throws {
        story.pages.removeAll { $0.id == page.id }
        modelContext.delete(page)

        // order を再設定
        for (index, existingPage) in story.sortedPages.enumerated() {
            existingPage.order = index
        }

        story.updatedAt = Date()
        try modelContext.save()
    }

    /// ページの順番を変更
    public func reorderPages(in story: PhotoStory, fromIndex: Int, toIndex: Int) throws {
        var sorted = story.sortedPages
        guard fromIndex >= 0, fromIndex < sorted.count,
              toIndex >= 0, toIndex < sorted.count else {
            throw PhotoStoryError.pageNotFound
        }

        let movedPage = sorted.remove(at: fromIndex)
        sorted.insert(movedPage, at: toIndex)

        for (index, page) in sorted.enumerated() {
            page.order = index
        }

        story.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - 変更保存

    /// 変更を保存（既存オブジェクトの更新時）
    public func save() throws {
        try modelContext.save()
    }
}
