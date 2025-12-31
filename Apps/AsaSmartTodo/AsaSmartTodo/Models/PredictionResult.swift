//
//  PredictionResult.swift
//  AsaSmartTodo
//
//  AI優先度予測の結果を表す構造体
//

import Foundation

/// AI予測の結果を保持する構造体
struct PredictionResult: Codable, Sendable {
    /// 提案された優先度
    let suggestedPriority: PriorityLevel

    /// 信頼度スコア（0.0-1.0）
    let confidenceScore: Double

    /// 予測理由のリスト
    let reasons: [PredictionReason]

    /// 信頼度をパーセンテージで取得
    var confidencePercentage: Int {
        Int(confidenceScore * 100)
    }

    /// 予測理由を日本語テキストに変換
    var reasonsText: String {
        reasons.map { "\($0.emoji) \($0.description)" }.joined(separator: " / ")
    }

    /// 信頼度の表示テキスト
    var confidenceText: String {
        switch confidenceScore {
        case 0.8...:
            return "非常に高い"
        case 0.6..<0.8:
            return "高い"
        case 0.4..<0.6:
            return "中程度"
        default:
            return "低い"
        }
    }
}

/// 予測の理由を表す構造体
struct PredictionReason: Codable, Sendable, Identifiable {
    let id: UUID
    let emoji: String
    let description: String
    let weight: Double  // この理由の重み（0.0-1.0）

    init(emoji: String, description: String, weight: Double) {
        self.id = UUID()
        self.emoji = emoji
        self.description = description
        self.weight = weight
    }

    // MARK: - Factory Methods

    /// 期限が迫っている理由
    static func dueDateUrgent(_ days: Int) -> PredictionReason {
        let desc: String
        if days < 0 {
            desc = "期限切れ（緊急）"
        } else if days == 0 {
            desc = "今日が期限"
        } else if days == 1 {
            desc = "明日が期限"
        } else {
            desc = "\(days)日後が期限"
        }
        return PredictionReason(emoji: "🚨", description: desc, weight: 0.35)
    }

    /// カテゴリが重要
    static func categoryImportant(_ category: TaskCategory) -> PredictionReason {
        PredictionReason(
            emoji: category.icon,
            description: "\(category.displayName)関連",
            weight: 0.20
        )
    }

    /// タイトルが複雑（詳細なタスク）
    static func complexTitle(_ wordCount: Int) -> PredictionReason {
        PredictionReason(
            emoji: "📝",
            description: "詳細なタスク内容（\(wordCount)単語）",
            weight: 0.15
        )
    }

    /// 説明文が詳細
    static func detailedDescription(_ charCount: Int) -> PredictionReason {
        PredictionReason(
            emoji: "📋",
            description: "詳細な説明あり（\(charCount)文字）",
            weight: 0.10
        )
    }

    /// 朝活時間帯に作成
    static func morningBoost() -> PredictionReason {
        PredictionReason(
            emoji: "🌅",
            description: "朝活時間（5:00-7:00）に作成",
            weight: 0.10
        )
    }

    /// 過去の完了率が低い
    static func historicalLowCompletion(_ rate: Double) -> PredictionReason {
        PredictionReason(
            emoji: "📊",
            description: "類似タスクの完了率が低い（\(Int(rate * 100))%）",
            weight: 0.10
        )
    }

    /// 過去の完了率が高い
    static func historicalHighCompletion(_ rate: Double) -> PredictionReason {
        PredictionReason(
            emoji: "✅",
            description: "類似タスクの完了率が高い（\(Int(rate * 100))%）",
            weight: 0.10
        )
    }
}
