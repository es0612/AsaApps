import Foundation

// MARK: - MoodScore

/// 気分スコア（5段階）
public enum MoodScore: String, CaseIterable, Codable, Sendable {
    case terrible
    case bad
    case neutral
    case good
    case great

    /// 数値（1〜5）
    public var numericValue: Int {
        switch self {
        case .terrible: return 1
        case .bad: return 2
        case .neutral: return 3
        case .good: return 4
        case .great: return 5
        }
    }

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .terrible: return "最悪"
        case .bad: return "悪い"
        case .neutral: return "普通"
        case .good: return "良い"
        case .great: return "最高"
        }
    }

    /// 絵文字
    public var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😟"
        case .neutral: return "😐"
        case .good: return "😊"
        case .great: return "😄"
        }
    }
}
