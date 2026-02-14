import Foundation

// MARK: - BusinessCategory

/// 地域店舗カテゴリ（7種）
public enum BusinessCategory: String, CaseIterable, Sendable {
    case restaurant = "飲食店"
    case grocery = "スーパー・食料品"
    case medical = "医療・薬局"
    case beauty = "美容・理容"
    case education = "教育・塾"
    case service = "サービス"
    case other = "その他"

    /// SF Symbol名
    public var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .grocery: return "cart"
        case .medical: return "cross.case"
        case .beauty: return "scissors"
        case .education: return "book"
        case .service: return "wrench.and.screwdriver"
        case .other: return "building.2"
        }
    }

    /// カラー（hex文字列）
    public var colorHex: String {
        switch self {
        case .restaurant: return "#D0021B"
        case .grocery: return "#7ED321"
        case .medical: return "#4A90D9"
        case .beauty: return "#F8A4C8"
        case .education: return "#F5A623"
        case .service: return "#7A918D"
        case .other: return "#9B9B9B"
        }
    }
}
