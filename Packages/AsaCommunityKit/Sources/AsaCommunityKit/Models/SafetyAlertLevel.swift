import Foundation

// MARK: - SafetyAlertLevel

/// 安全警戒レベル（4段階）
public enum SafetyAlertLevel: String, CaseIterable, Sendable, Comparable {
    case info = "お知らせ"
    case caution = "注意"
    case warning = "警告"
    case emergency = "緊急"

    /// SF Symbol名
    public var iconName: String {
        switch self {
        case .info: return "info.circle"
        case .caution: return "exclamationmark.triangle"
        case .warning: return "exclamationmark.octagon"
        case .emergency: return "light.beacon.max"
        }
    }

    /// カラー（hex文字列）
    public var colorHex: String {
        switch self {
        case .info: return "#4A90D9"
        case .caution: return "#F5A623"
        case .warning: return "#F5A623"
        case .emergency: return "#D0021B"
        }
    }

    /// 重要度（比較用）
    private var severity: Int {
        switch self {
        case .info: return 0
        case .caution: return 1
        case .warning: return 2
        case .emergency: return 3
        }
    }

    public static func < (lhs: SafetyAlertLevel, rhs: SafetyAlertLevel) -> Bool {
        lhs.severity < rhs.severity
    }
}
