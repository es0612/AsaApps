import Foundation

// MARK: - ライフドメイン

public enum LifeDomain: String, CaseIterable, Sendable, Codable {
    case morning
    case health
    case family
    case finance
    case community
    case learning

    public var displayName: String {
        switch self {
        case .morning: "朝活"
        case .health: "健康"
        case .family: "家族"
        case .finance: "資産"
        case .community: "地域"
        case .learning: "学習"
        }
    }

    public var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .health: "heart.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .finance: "yensign.circle.fill"
        case .community: "building.2.fill"
        case .learning: "book.fill"
        }
    }

    public var emoji: String {
        switch self {
        case .morning: "☀️"
        case .health: "❤️"
        case .family: "👨‍👩‍👧"
        case .finance: "💰"
        case .community: "🏘️"
        case .learning: "📚"
        }
    }

    public var accentColorHex: String {
        switch self {
        case .morning: "#FF9500"
        case .health: "#FF2D55"
        case .family: "#5856D6"
        case .finance: "#34C759"
        case .community: "#007AFF"
        case .learning: "#AF52DE"
        }
    }
}
