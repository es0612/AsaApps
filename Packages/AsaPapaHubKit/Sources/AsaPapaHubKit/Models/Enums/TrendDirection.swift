import Foundation

// MARK: - トレンド方向

public enum TrendDirection: String, CaseIterable, Sendable, Codable {
    case up
    case down
    case stable

    public var displayName: String {
        switch self {
        case .up: "上昇"
        case .down: "下降"
        case .stable: "安定"
        }
    }

    public var icon: String {
        switch self {
        case .up: "arrow.up.right"
        case .down: "arrow.down.right"
        case .stable: "arrow.right"
        }
    }

    public var isPositive: Bool {
        switch self {
        case .up: true
        case .down: false
        case .stable: true
        }
    }
}
