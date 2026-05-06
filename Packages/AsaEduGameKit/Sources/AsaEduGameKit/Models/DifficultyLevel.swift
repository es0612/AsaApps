import Foundation

// MARK: - 難易度レベル

/// ゲームの難易度設定（3段階）
public enum DifficultyLevel: String, CaseIterable, Codable, Sendable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"

    /// 表示名（子供向けひらがな）
    public var displayName: String {
        switch self {
        case .easy: return "やさしい"
        case .normal: return "ふつう"
        case .hard: return "むずかしい"
        }
    }

    /// 星ポイントの倍率
    public var starMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .normal: return 1.5
        case .hard: return 2.0
        }
    }

    /// 1セッションの問題数
    public var questionsPerSession: Int {
        switch self {
        case .easy: return 5
        case .normal: return 8
        case .hard: return 10
        }
    }

    /// 回答制限時間（秒）
    public var timeLimitSeconds: TimeInterval {
        switch self {
        case .easy: return 30.0
        case .normal: return 20.0
        case .hard: return 15.0
        }
    }

    /// 難易度の絵文字表示（後方互換用）
    public var emoji: String {
        switch self {
        case .easy: return "⭐"
        case .normal: return "⭐⭐"
        case .hard: return "⭐⭐⭐"
        }
    }

    /// 難易度を星数で表現（SF Symbols 表示用）
    public var starCount: Int {
        switch self {
        case .easy: return 1
        case .normal: return 2
        case .hard: return 3
        }
    }
}
