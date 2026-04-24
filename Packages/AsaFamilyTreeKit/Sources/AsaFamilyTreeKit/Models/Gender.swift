import SwiftUI

/// 性別を表すenum
public enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    case other = "other"

    // MARK: - Display Properties

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        }
    }

    /// アイコン名（SF Symbols）
    public var iconName: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .other: return "person.fill"
        }
    }

    /// 性別に対応する色
    /// AsaColors に準拠（AsaUIKit 依存を避けるため RGB を複製定義）：
    /// - male: `AsaColors.coffeeBrown` #C68C53（温かい茶系）
    /// - female: softCream を濃くした暖色 #D9A679
    /// - other: `AsaColors.mutedSage` #7A918D
    public var color: Color {
        switch self {
        case .male: return Color(red: 0.776, green: 0.549, blue: 0.325)
        case .female: return Color(red: 0.851, green: 0.651, blue: 0.471)
        case .other: return Color(red: 0.478, green: 0.569, blue: 0.553)
        }
    }

    /// ノード背景色（薄い色）
    public var nodeBackgroundColor: Color {
        color.opacity(0.18)
    }

    /// ノードボーダー色
    public var nodeBorderColor: Color {
        color
    }
}
