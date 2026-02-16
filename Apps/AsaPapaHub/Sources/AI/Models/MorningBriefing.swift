//
//  MorningBriefing.swift
//  AsaPapaHub
//
//  Foundation Models用の朝ブリーフィング@Generableモデル
//

import Foundation
import FoundationModels

// MARK: - 朝のブリーフィング（AI生成用）

/// AI が生成する朝のブリーフィングデータ
@Generable
struct MorningBriefingGenerable: Equatable, Sendable {
    /// 朝の挨拶メッセージ
    @Guide(description: "朝の挨拶メッセージ（日本語、温かみのある言葉で）")
    let greeting: String

    /// 今日のスケジュール概要
    @Guide(description: "今日のスケジュール概要（日本語、簡潔に）")
    let scheduleOverview: String

    /// 健康アドバイス
    @Guide(description: "健康アドバイス（日本語、昨日の歩数・睡眠に基づいて）")
    let healthAdvice: String

    /// モチベーショナルメッセージ
    @Guide(description: "モチベーショナルメッセージ（日本語、朝活パパを応援する言葉）")
    let motivationalMessage: String
}
