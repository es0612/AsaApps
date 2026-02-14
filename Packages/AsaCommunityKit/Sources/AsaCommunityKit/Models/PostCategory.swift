import Foundation

// MARK: - PostCategory

/// 掲示板投稿カテゴリ（8種）
public enum PostCategory: String, CaseIterable, Sendable {
    case event = "イベント"
    case question = "質問"
    case giveaway = "譲ります"
    case wanted = "探しています"
    case circular = "回覧板"
    case safety = "防犯・防災"
    case parenting = "子育て"
    case general = "一般"

    /// SF Symbol名
    public var iconName: String {
        switch self {
        case .event: return "calendar.badge.clock"
        case .question: return "questionmark.circle"
        case .giveaway: return "gift"
        case .wanted: return "magnifyingglass"
        case .circular: return "doc.text"
        case .safety: return "shield.checkered"
        case .parenting: return "figure.and.child.holdinghands"
        case .general: return "bubble.left.and.bubble.right"
        }
    }

    /// カテゴリカラー（hex文字列）
    public var colorHex: String {
        switch self {
        case .event: return "#4A90D9"
        case .question: return "#F5A623"
        case .giveaway: return "#7ED321"
        case .wanted: return "#BD10E0"
        case .circular: return "#C68C53"
        case .safety: return "#D0021B"
        case .parenting: return "#F8A4C8"
        case .general: return "#7A918D"
        }
    }
}
