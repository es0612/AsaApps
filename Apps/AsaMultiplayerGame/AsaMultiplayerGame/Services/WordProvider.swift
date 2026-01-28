//
//  WordProvider.swift
//  AsaMultiplayerGame
//
//  お題（描くもの）の提供サービス
//

import Foundation

/// お題提供サービス
///
/// お絵かきゲームで使用するお題（描くもの）を提供します。
/// カテゴリ別にお題を管理し、ランダムに選択します。
struct WordProvider: Sendable {
    // MARK: - Categories

    /// お題のカテゴリ
    enum Category: String, CaseIterable, Sendable {
        case animals = "動物"
        case food = "食べ物"
        case nature = "自然"
        case objects = "もの"
        case vehicles = "乗り物"
        case buildings = "建物"
        case activities = "動作"
        case characters = "キャラクター"
    }

    // MARK: - Word Lists

    /// カテゴリ別のお題リスト
    private static let wordsByCategory: [Category: [String]] = [
        .animals: [
            "いぬ", "ねこ", "うさぎ", "ぞう", "きりん",
            "ライオン", "さる", "くま", "パンダ", "ペンギン",
            "とり", "さかな", "かめ", "へび", "かえる",
            "うま", "うし", "ぶた", "ひつじ", "にわとり"
        ],
        .food: [
            "りんご", "バナナ", "みかん", "いちご", "ぶどう",
            "ケーキ", "アイスクリーム", "ピザ", "ハンバーガー", "すし",
            "おにぎり", "ラーメン", "カレーライス", "たまご", "パン",
            "にんじん", "トマト", "きゅうり", "キャベツ", "とうもろこし"
        ],
        .nature: [
            "たいよう", "つき", "ほし", "くも", "あめ",
            "にじ", "やま", "かわ", "うみ", "もり",
            "はな", "き", "はっぱ", "きのこ", "さぼてん"
        ],
        .objects: [
            "でんわ", "テレビ", "パソコン", "ほん", "えんぴつ",
            "はさみ", "かぎ", "めがね", "かさ", "ぼうし",
            "くつ", "かばん", "とけい", "カメラ", "ギター"
        ],
        .vehicles: [
            "くるま", "バス", "でんしゃ", "ひこうき", "ふね",
            "じてんしゃ", "オートバイ", "ヘリコプター", "ロケット", "しょうぼうしゃ",
            "パトカー", "きゅうきゅうしゃ", "トラック", "タクシー", "しんかんせん"
        ],
        .buildings: [
            "いえ", "マンション", "びょういん", "がっこう", "えき",
            "スーパー", "コンビニ", "としょかん", "こうえん", "どうぶつえん"
        ],
        .activities: [
            "およぐ", "はしる", "とぶ", "ねる", "たべる",
            "うたう", "おどる", "かく", "よむ", "あそぶ"
        ],
        .characters: [
            "おうさま", "おひめさま", "まほうつかい", "にんじゃ", "ロボット",
            "かいぞく", "ゆうしゃ", "サンタクロース", "おに", "てんし"
        ]
    ]

    // MARK: - Public Methods

    /// ランダムなお題を取得
    /// - Parameter excludeWords: 除外するお題（既出のお題）
    /// - Returns: ランダムに選択されたお題
    static func randomWord(excluding excludeWords: Set<String> = []) -> String {
        let allWords = wordsByCategory.values.flatMap { $0 }
        let availableWords = allWords.filter { !excludeWords.contains($0) }

        if availableWords.isEmpty {
            // 全てのお題が使用済みの場合はリセット
            return allWords.randomElement() ?? "りんご"
        }

        return availableWords.randomElement() ?? "りんご"
    }

    /// 特定のカテゴリからランダムなお題を取得
    /// - Parameters:
    ///   - category: カテゴリ
    ///   - excludeWords: 除外するお題
    /// - Returns: ランダムに選択されたお題
    static func randomWord(
        from category: Category,
        excluding excludeWords: Set<String> = []
    ) -> String {
        guard let words = wordsByCategory[category] else {
            return randomWord(excluding: excludeWords)
        }

        let availableWords = words.filter { !excludeWords.contains($0) }

        if availableWords.isEmpty {
            return words.randomElement() ?? "りんご"
        }

        return availableWords.randomElement() ?? "りんご"
    }

    /// 複数のランダムなお題を取得（選択肢として表示用）
    /// - Parameters:
    ///   - count: 取得する数
    ///   - excludeWords: 除外するお題
    /// - Returns: ランダムに選択されたお題の配列
    static func randomWords(count: Int, excluding excludeWords: Set<String> = []) -> [String] {
        let allWords = wordsByCategory.values.flatMap { $0 }
        var availableWords = allWords.filter { !excludeWords.contains($0) }
        var result: [String] = []

        for _ in 0..<count {
            guard !availableWords.isEmpty else { break }
            if let word = availableWords.randomElement(),
               let index = availableWords.firstIndex(of: word) {
                result.append(word)
                availableWords.remove(at: index)
            }
        }

        return result
    }
}

// MARK: - Answer Matching

extension WordProvider {
    /// 回答が正解かどうかを判定
    /// - Parameters:
    ///   - answer: 回答
    ///   - correctWord: 正解のお題
    /// - Returns: 正解かどうか
    static func isCorrectAnswer(_ answer: String, correctWord: String) -> Bool {
        // 空白を除去して比較
        let normalizedAnswer = normalizeText(answer)
        let normalizedCorrect = normalizeText(correctWord)

        // 完全一致
        if normalizedAnswer == normalizedCorrect {
            return true
        }

        // ひらがな/カタカナを統一して比較
        let hiraganaAnswer = toHiragana(normalizedAnswer)
        let hiraganaCorrect = toHiragana(normalizedCorrect)

        return hiraganaAnswer == hiraganaCorrect
    }

    /// テキストを正規化（空白除去、小文字化）
    private static func normalizeText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// カタカナをひらがなに変換
    private static func toHiragana(_ text: String) -> String {
        var result = ""
        for char in text.unicodeScalars {
            // カタカナの範囲: U+30A0 - U+30FF
            // ひらがなの範囲: U+3040 - U+309F
            if char.value >= 0x30A0 && char.value <= 0x30FF {
                if let hiragana = UnicodeScalar(char.value - 0x60) {
                    result.append(Character(hiragana))
                } else {
                    result.append(Character(char))
                }
            } else {
                result.append(Character(char))
            }
        }
        return result
    }
}
