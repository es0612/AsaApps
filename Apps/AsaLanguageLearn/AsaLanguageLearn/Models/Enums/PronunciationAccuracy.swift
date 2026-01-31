//
//  PronunciationAccuracy.swift
//  AsaLanguageLearn
//
//  発音精度の評価レベル
//

import SwiftUI

/// 発音精度の評価レベル
/// 認識テキストとターゲットテキストの類似度に基づく4段階評価
enum PronunciationAccuracy: String, CaseIterable, Codable, Sendable {
    /// 完璧な発音（90%以上の一致）
    case perfect = "perfect"
    /// 良好な発音（70%以上の一致）
    case good = "good"
    /// まずまずの発音（50%以上の一致）
    case fair = "fair"
    /// 改善が必要（50%未満の一致）
    case needsWork = "needs_work"

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .perfect: return "Perfect!"
        case .good: return "Good!"
        case .fair: return "Fair"
        case .needsWork: return "Keep Trying"
        }
    }

    var displayNameJapanese: String {
        switch self {
        case .perfect: return "完璧！"
        case .good: return "良い！"
        case .fair: return "まずまず"
        case .needsWork: return "もう一度"
        }
    }

    var icon: String {
        switch self {
        case .perfect: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "circle.fill"
        case .needsWork: return "arrow.clockwise"
        }
    }

    var color: Color {
        switch self {
        case .perfect: return Color.yellow
        case .good: return Color.green
        case .fair: return Color.orange
        case .needsWork: return Color.red
        }
    }

    var emoji: String {
        switch self {
        case .perfect: return "🌟"
        case .good: return "👍"
        case .fair: return "👌"
        case .needsWork: return "💪"
        }
    }

    var feedbackMessage: String {
        switch self {
        case .perfect: return "素晴らしい発音です！ネイティブのように聞こえます。"
        case .good: return "とても良い発音です！少し練習すれば完璧になります。"
        case .fair: return "良い調子です。ゆっくり発音してみましょう。"
        case .needsWork: return "お手本を聞いて、もう一度挑戦してみましょう。"
        }
    }

    /// スコアは正解としてカウントするか
    var countsAsCorrect: Bool {
        switch self {
        case .perfect, .good: return true
        case .fair, .needsWork: return false
        }
    }

    // MARK: - Score Thresholds

    /// 最小スコア（この値以上でこのレベル）
    var minimumScore: Double {
        switch self {
        case .perfect: return 0.9
        case .good: return 0.7
        case .fair: return 0.5
        case .needsWork: return 0.0
        }
    }

    /// スコアから精度レベルを判定
    static func from(score: Double) -> PronunciationAccuracy {
        let clampedScore = max(0.0, min(1.0, score))
        switch clampedScore {
        case 0.9...1.0: return .perfect
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        default: return .needsWork
        }
    }
}
