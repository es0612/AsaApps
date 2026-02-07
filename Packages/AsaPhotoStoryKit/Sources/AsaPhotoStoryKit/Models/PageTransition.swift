import Foundation

// MARK: - PageTransition

/// ページ間のトランジション効果
public enum PageTransition: String, CaseIterable, Codable, Sendable {
    case none
    case fade
    case slide
    case dissolve
    case push

    // MARK: - Properties

    public var displayName: String {
        switch self {
        case .none: "なし"
        case .fade: "フェード"
        case .slide: "スライド"
        case .dissolve: "ディゾルブ"
        case .push: "プッシュ"
        }
    }

    /// トランジションのデフォルト所要時間（秒）
    public var defaultDuration: TimeInterval {
        switch self {
        case .none: 0
        case .fade: 0.5
        case .slide: 0.4
        case .dissolve: 0.6
        case .push: 0.3
        }
    }
}
