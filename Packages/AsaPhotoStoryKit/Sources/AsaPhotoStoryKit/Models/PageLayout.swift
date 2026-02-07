import Foundation

// MARK: - PageLayout

/// ページ内のレイアウト種類
public enum PageLayout: String, CaseIterable, Codable, Sendable {
    case singlePhoto
    case twoHorizontal
    case twoVertical
    case threeGrid
    case fourGrid
    case photoWithText
    case textOnly
    case freeform

    // MARK: - Properties

    public var displayName: String {
        switch self {
        case .singlePhoto: "1枚写真"
        case .twoHorizontal: "横2枚"
        case .twoVertical: "縦2枚"
        case .threeGrid: "3枚グリッド"
        case .fourGrid: "4枚グリッド"
        case .photoWithText: "写真+テキスト"
        case .textOnly: "テキストのみ"
        case .freeform: "自由配置"
        }
    }

    public var iconName: String {
        switch self {
        case .singlePhoto: "rectangle"
        case .twoHorizontal: "rectangle.split.1x2"
        case .twoVertical: "rectangle.split.2x1"
        case .threeGrid: "rectangle.split.3x1"
        case .fourGrid: "rectangle.split.2x2"
        case .photoWithText: "text.below.photo"
        case .textOnly: "text.alignleft"
        case .freeform: "square.dashed"
        }
    }

    /// レイアウトごとの推奨要素数
    public var elementCount: Int {
        switch self {
        case .singlePhoto: 1
        case .twoHorizontal, .twoVertical: 2
        case .threeGrid: 3
        case .fourGrid: 4
        case .photoWithText: 2
        case .textOnly: 1
        case .freeform: 0
        }
    }
}
