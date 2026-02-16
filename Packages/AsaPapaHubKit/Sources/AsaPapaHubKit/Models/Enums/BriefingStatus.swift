import Foundation

// MARK: - ブリーフィングステータス

public enum BriefingStatus: String, CaseIterable, Sendable, Codable {
    case pending
    case generating
    case completed
    case failed

    public var displayName: String {
        switch self {
        case .pending: "待機中"
        case .generating: "生成中"
        case .completed: "完了"
        case .failed: "失敗"
        }
    }

    public var icon: String {
        switch self {
        case .pending: "clock"
        case .generating: "sparkles"
        case .completed: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }
}
