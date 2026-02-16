import Foundation

// MARK: - ルーティンアイテムステータス

public enum RoutineItemStatus: String, CaseIterable, Sendable, Codable {
    case pending
    case inProgress
    case completed
    case skipped

    public var displayName: String {
        switch self {
        case .pending: "未着手"
        case .inProgress: "進行中"
        case .completed: "完了"
        case .skipped: "スキップ"
        }
    }

    public var icon: String {
        switch self {
        case .pending: "circle"
        case .inProgress: "circle.dotted.circle"
        case .completed: "checkmark.circle.fill"
        case .skipped: "forward.fill"
        }
    }
}
