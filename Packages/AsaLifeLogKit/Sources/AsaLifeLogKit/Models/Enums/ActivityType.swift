import Foundation

// MARK: - ActivityType

/// アクティビティ種別
public enum ActivityType: String, CaseIterable, Codable, Sendable {
    case stationary
    case walking
    case running
    case cycling
    case driving

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .stationary: return "静止"
        case .walking: return "徒歩"
        case .running: return "ランニング"
        case .cycling: return "自転車"
        case .driving: return "車"
        }
    }

    /// SF Symbol名
    public var icon: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        }
    }
}
