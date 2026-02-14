import Foundation

// MARK: - PlaceCategory

/// 場所カテゴリ
public enum PlaceCategory: String, CaseIterable, Codable, Sendable {
    case home
    case work
    case restaurant
    case shop
    case park
    case gym
    case other

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .home: return "自宅"
        case .work: return "職場"
        case .restaurant: return "飲食店"
        case .shop: return "お店"
        case .park: return "公園"
        case .gym: return "ジム"
        case .other: return "その他"
        }
    }

    /// SF Symbol名
    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .restaurant: return "fork.knife"
        case .shop: return "cart.fill"
        case .park: return "leaf.fill"
        case .gym: return "dumbbell.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}
