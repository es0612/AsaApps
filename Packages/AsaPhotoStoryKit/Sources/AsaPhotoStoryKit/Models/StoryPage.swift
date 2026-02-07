import Foundation
import SwiftData

// MARK: - StoryPage

/// ストーリーの1ページを管理するSwiftDataモデル
/// レイアウト、トランジション、背景色、要素を保持
@Model
public final class StoryPage {
    // MARK: - Properties

    /// 一意識別子
    public var id: UUID

    /// ページ順序
    public var order: Int

    /// レイアウト種類（rawValue保存）
    public var layoutRawValue: String

    /// 背景色HEX
    public var backgroundColorHex: String?

    /// トランジション種類（rawValue保存）
    public var transitionRawValue: String

    /// ページ表示時間（秒）
    public var duration: TimeInterval

    /// 背景画像データ
    @Attribute(.externalStorage)
    public var backgroundImageData: Data?

    /// ページ上の要素一覧（カスケード削除）
    @Relationship(deleteRule: .cascade, inverse: \StoryElement.page)
    public var elements: [StoryElement]

    /// 親ストーリー
    public var story: PhotoStory?

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        order: Int = 0,
        layout: PageLayout = .singlePhoto,
        backgroundColorHex: String? = nil,
        transition: PageTransition = .fade,
        duration: TimeInterval = 3.0
    ) {
        self.id = id
        self.order = order
        self.layoutRawValue = layout.rawValue
        self.backgroundColorHex = backgroundColorHex
        self.transitionRawValue = transition.rawValue
        self.duration = duration
        self.elements = []
    }

    // MARK: - Computed Properties

    /// レイアウト型変換
    public var layout: PageLayout {
        get { PageLayout(rawValue: layoutRawValue) ?? .singlePhoto }
        set {
            layoutRawValue = newValue.rawValue
        }
    }

    /// トランジション型変換
    public var transition: PageTransition {
        get { PageTransition(rawValue: transitionRawValue) ?? .fade }
        set {
            transitionRawValue = newValue.rawValue
        }
    }

    /// 要素をzOrder順でソートして取得
    public var sortedElements: [StoryElement] {
        elements.sorted { $0.zOrder < $1.zOrder }
    }

    /// 要素数
    public var elementCount: Int {
        elements.count
    }
}
