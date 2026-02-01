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
    public var color: Color {
        switch self {
        case .male: return Color(red: 0.3, green: 0.5, blue: 0.8) // 青系
        case .female: return Color(red: 0.8, green: 0.4, blue: 0.5) // ピンク系
        case .other: return Color(red: 0.5, green: 0.6, blue: 0.5) // グリーン系
        }
    }

    /// ノード背景色（薄い色）
    public var nodeBackgroundColor: Color {
        color.opacity(0.2)
    }

    /// ノードボーダー色
    public var nodeBorderColor: Color {
        color
    }
}
