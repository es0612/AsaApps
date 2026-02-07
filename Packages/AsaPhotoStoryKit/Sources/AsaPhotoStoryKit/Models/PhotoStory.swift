import Foundation
import SwiftData

// MARK: - PhotoStory

/// フォトストーリー本体を管理するSwiftDataモデル
/// 複数ページを持ち、テンプレートとテーマでスタイルを設定
@Model
public final class PhotoStory {
    // MARK: - Properties

    /// 一意識別子
    public var id: UUID

    /// ストーリータイトル
    public var title: String

    /// 説明文
    public var storyDescription: String?

    /// テンプレート種類（rawValue保存）
    public var templateRawValue: String

    /// テーマ種類（rawValue保存）
    public var themeRawValue: String

    /// 作成日時
    public var createdAt: Date

    /// 更新日時
    public var updatedAt: Date

    /// お気に入りフラグ
    public var isFavorite: Bool

    /// タグ配列（JSON Data）
    public var tagsJSON: Data?

    /// サムネイル画像データ
    @Attribute(.externalStorage)
    public var thumbnailData: Data?

    /// ページ一覧（カスケード削除）
    @Relationship(deleteRule: .cascade, inverse: \StoryPage.story)
    public var pages: [StoryPage]

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        title: String = "新しいストーリー",
        storyDescription: String? = nil,
        template: StoryTemplate = .blank,
        theme: StoryTheme = .warm,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.storyDescription = storyDescription
        self.templateRawValue = template.rawValue
        self.themeRawValue = theme.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.pages = []
    }

    // MARK: - Computed Properties

    /// テンプレート型変換
    public var template: StoryTemplate {
        get { StoryTemplate(rawValue: templateRawValue) ?? .blank }
        set {
            templateRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// テーマ型変換
    public var theme: StoryTheme {
        get { StoryTheme(rawValue: themeRawValue) ?? .warm }
        set {
            themeRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// タグ配列（JSON変換）
    public var tags: [String] {
        get {
            guard let data = tagsJSON else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsJSON = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// ページ数
    public var pageCount: Int {
        pages.count
    }

    /// ページをorder順でソートして取得
    public var sortedPages: [StoryPage] {
        pages.sorted { $0.order < $1.order }
    }
}
