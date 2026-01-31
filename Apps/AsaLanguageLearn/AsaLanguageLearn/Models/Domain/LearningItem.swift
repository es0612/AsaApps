//
//  LearningItem.swift
//  AsaLanguageLearn
//
//  学習アイテム（発音練習の単位）
//

import Foundation
import SwiftData

/// 学習アイテム
/// 発音練習する単語やフレーズ
@Model
final class LearningItem {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID

    /// 英語テキスト（発音ターゲット）
    var englishText: String

    /// 日本語訳
    var japaneseText: String

    /// 発音記号（IPA）
    var pronunciation: String?

    /// 例文（英語）
    var exampleSentence: String?

    /// 例文の日本語訳
    var exampleTranslation: String?

    /// 発音のヒント・コツ
    var pronunciationTip: String?

    /// 音声ファイルのURL（オフライン用）
    var audioURL: String?

    var sortOrder: Int
    var createdAt: Date

    var lesson: Lesson?

    @Relationship(deleteRule: .cascade, inverse: \LearningProgress.item)
    var progress: LearningProgress?

    // MARK: - Computed Properties

    var masteryLevel: MasteryLevel {
        progress?.masteryLevel ?? .new
    }

    var isNew: Bool {
        progress?.isStudied != true
    }

    var needsReview: Bool {
        progress?.needsReview ?? false
    }

    var lastStudiedText: String? {
        guard let lastStudied = progress?.lastStudiedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: lastStudied, relativeTo: Date())
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        englishText: String,
        japaneseText: String,
        pronunciation: String? = nil,
        exampleSentence: String? = nil,
        exampleTranslation: String? = nil,
        pronunciationTip: String? = nil,
        audioURL: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.englishText = englishText
        self.japaneseText = japaneseText
        self.pronunciation = pronunciation
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.pronunciationTip = pronunciationTip
        self.audioURL = audioURL
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Sample Data

extension LearningItem {
    static var sampleGoodMorning: LearningItem {
        LearningItem(
            englishText: "Good morning",
            japaneseText: "おはようございます",
            pronunciation: "/ɡʊd ˈmɔːrnɪŋ/",
            exampleSentence: "Good morning! How are you today?",
            exampleTranslation: "おはようございます！今日の調子はいかがですか？",
            pronunciationTip: "「グッモーニン」と発音。morningの「r」は舌を丸めずに。",
            sortOrder: 0
        )
    }

    static var sampleHowAreYou: LearningItem {
        LearningItem(
            englishText: "How are you?",
            japaneseText: "お元気ですか？",
            pronunciation: "/haʊ ɑːr juː/",
            exampleSentence: "Hi there! How are you doing?",
            exampleTranslation: "こんにちは！調子はどう？",
            pronunciationTip: "「ハウアーユー」と滑らかに。areは弱く発音。",
            sortOrder: 1
        )
    }

    static var sampleNiceToMeetYou: LearningItem {
        LearningItem(
            englishText: "Nice to meet you",
            japaneseText: "はじめまして",
            pronunciation: "/naɪs tuː miːt juː/",
            exampleSentence: "Hi, I'm Taro. Nice to meet you!",
            exampleTranslation: "こんにちは、太郎です。はじめまして！",
            pronunciationTip: "「ナイストゥミーチュー」。meetのtは軽く。",
            sortOrder: 2
        )
    }
}
