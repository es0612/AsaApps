//
//  WeeklySummaryReport.swift
//  AsaPapaHub
//
//  Foundation Models用の週間サマリー@Generableモデル
//

import Foundation
import FoundationModels

// MARK: - 週間サマリーレポート（AI生成用）

/// AI が生成する週間サマリーレポート
@Generable
struct WeeklySummaryReport: Equatable, Sendable {
    /// 週間の総括
    @Guide(description: "週間の総括（日本語、2-3文で）")
    let summary: String

    /// 今週のハイライト
    @Guide(description: "今週のハイライト（日本語）", .count(1...5))
    let highlights: [String]

    /// 来週への提案
    @Guide(description: "来週への提案（日本語）", .count(1...3))
    let suggestions: [String]

    /// 応援メッセージ
    @Guide(description: "応援メッセージ（日本語）")
    let encouragement: String
}
