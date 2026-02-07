import Foundation

// MARK: - StoryTheme

/// ストーリーのテーマカラー設定
public enum StoryTheme: String, CaseIterable, Codable, Sendable {
    case warm
    case cool
    case classic
    case pastel
    case monochrome
    case natural

    // MARK: - Properties

    public var displayName: String {
        switch self {
        case .warm: "ウォーム"
        case .cool: "クール"
        case .classic: "クラシック"
        case .pastel: "パステル"
        case .monochrome: "モノクロ"
        case .natural: "ナチュラル"
        }
    }

    public var primaryColorHex: String {
        switch self {
        case .warm: "#C68C53"
        case .cool: "#4A90D9"
        case .classic: "#2F3E46"
        case .pastel: "#FFB5E8"
        case .monochrome: "#333333"
        case .natural: "#6B8E6B"
        }
    }

    public var secondaryColorHex: String {
        switch self {
        case .warm: "#8B5A2B"
        case .cool: "#7AB8F5"
        case .classic: "#7A918D"
        case .pastel: "#B5DEFF"
        case .monochrome: "#666666"
        case .natural: "#A8C69F"
        }
    }

    public var backgroundColorHex: String {
        switch self {
        case .warm: "#FFF8F0"
        case .cool: "#F0F5FF"
        case .classic: "#F5F0EB"
        case .pastel: "#FFF5F9"
        case .monochrome: "#F5F5F5"
        case .natural: "#F0F5EC"
        }
    }
}
