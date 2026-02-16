//
//  AISearchResult.swift
//  AsaPapaHub
//
//  Foundation Models用の自然言語検索結果@Generableモデル
//

import Foundation
import FoundationModels

// MARK: - AI検索結果（AI生成用）

/// AI が生成する自然言語検索結果
@Generable
struct AISearchResult: Equatable, Sendable {
    /// 検索クエリへの回答
    @Guide(description: "検索クエリへの回答（日本語、簡潔に）")
    let answer: String

    /// 関連するドメイン
    @Guide(description: "関連するライフドメイン名（朝活、健康、家族、資産、地域、学習のいずれか）", .count(1...6))
    let relatedDomains: [String]

    /// 提案されるアクション
    @Guide(description: "提案されるアクション（日本語）", .count(0...3))
    let suggestedActions: [String]
}
