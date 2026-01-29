//
//  CommandParserService.swift
//  AsaVoiceAssistant
//
//  音声認識テキストからコマンドを解析するサービス
//

import Foundation

/// 音声認識テキストからコマンドを解析するサービス
///
/// 日本語の自然言語コマンドを解析し、タスク操作に変換します。
/// 正規表現パターンマッチングで意図を検出し、期限や優先度などの
/// パラメータを抽出します。
final class CommandParserService: Sendable {
    // MARK: - Singleton

    static let shared = CommandParserService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 音声認識テキストを解析してコマンドを生成
    /// - Parameter text: 音声認識されたテキスト
    /// - Returns: 解析結果のVoiceCommand
    func parse(_ text: String) -> VoiceCommand {
        let normalizedText = normalizeText(text)

        // 各インテントのパターンをチェック
        for intent in CommandIntent.allCases where intent != .unknown {
            if let command = tryMatchIntent(intent, text: normalizedText) {
                return command
            }
        }

        // タスク作成のフォールバック: 動詞で終わるものはタスクとして扱う
        if let taskTitle = extractTaskTitleFallback(normalizedText) {
            return VoiceCommand(
                intent: .createTask,
                taskTitle: taskTitle,
                priority: extractPriority(from: normalizedText),
                category: extractCategory(from: normalizedText),
                dueDate: extractDueDate(from: normalizedText),
                rawTranscription: text,
                confidence: 0.6
            )
        }

        return VoiceCommand.unknown(rawTranscription: text)
    }

    // MARK: - Private Methods

    /// テキストを正規化
    private func normalizeText(_ text: String) -> String {
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 全角数字を半角に変換
        let fullWidthDigits = "０１２３４５６７８９"
        let halfWidthDigits = "0123456789"
        for (full, half) in zip(fullWidthDigits, halfWidthDigits) {
            normalized = normalized.replacingOccurrences(of: String(full), with: String(half))
        }

        return normalized
    }

    /// 指定されたインテントのパターンにマッチするか確認
    private func tryMatchIntent(_ intent: CommandIntent, text: String) -> VoiceCommand? {
        for pattern in intent.patterns {
            if let _ = text.range(of: pattern, options: .regularExpression) {
                return buildCommand(for: intent, text: text, pattern: pattern)
            }
        }
        return nil
    }

    /// インテントに応じたコマンドを構築
    private func buildCommand(for intent: CommandIntent, text: String, pattern: String) -> VoiceCommand {
        switch intent {
        case .createTask:
            let title = extractTaskTitle(from: text, pattern: pattern)
            return VoiceCommand(
                intent: .createTask,
                taskTitle: title,
                priority: extractPriority(from: text),
                category: extractCategory(from: text),
                dueDate: extractDueDate(from: text),
                rawTranscription: text,
                confidence: title != nil ? 0.85 : 0.5
            )

        case .completeTask:
            let query = extractTargetTaskQuery(from: text, pattern: pattern)
            return VoiceCommand(
                intent: .completeTask,
                targetTaskQuery: query,
                rawTranscription: text,
                confidence: query != nil ? 0.85 : 0.5
            )

        case .deleteTask:
            let query = extractTargetTaskQuery(from: text, pattern: pattern)
            return VoiceCommand(
                intent: .deleteTask,
                targetTaskQuery: query,
                rawTranscription: text,
                confidence: query != nil ? 0.85 : 0.5
            )

        case .listTasks:
            return VoiceCommand(
                intent: .listTasks,
                filterPriority: extractFilterPriority(from: text),
                filterCategory: extractCategory(from: text),
                rawTranscription: text,
                confidence: 0.9
            )

        case .readTasks:
            return VoiceCommand(
                intent: .readTasks,
                filterPriority: extractFilterPriority(from: text),
                filterCategory: extractCategory(from: text),
                rawTranscription: text,
                confidence: 0.9
            )

        case .unknown:
            return VoiceCommand.unknown(rawTranscription: text)
        }
    }

    /// タスクタイトルを抽出
    private func extractTaskTitle(from text: String, pattern: String) -> String? {
        // パターンからキャプチャグループを抽出
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // 最初のキャプチャグループをタイトルとして使用
        if match.numberOfRanges > 1 {
            let titleRange = match.range(at: 1)
            if let swiftRange = Range(titleRange, in: text) {
                var title = String(text[swiftRange])
                // 不要な接尾辞を削除
                title = removeCommonSuffixes(from: title)
                return title.isEmpty ? nil : title
            }
        }

        return nil
    }

    /// タスクタイトルのフォールバック抽出（動詞で終わる文）
    private func extractTaskTitleFallback(_ text: String) -> String? {
        let verbEndings = ["する", "やる", "行く", "送る", "買う", "作る", "書く", "読む", "見る", "聞く", "話す", "食べる", "飲む", "寝る", "起きる", "出す", "入れる", "取る", "持つ", "置く", "開ける", "閉める", "始める", "終える", "続ける"]

        for ending in verbEndings {
            if text.hasSuffix(ending) {
                return text
            }
        }

        // 「〜しなきゃ」「〜しないと」パターン
        let mustPatterns = ["しなきゃ", "しないと", "しなければ", "しなくては"]
        for pattern in mustPatterns {
            if text.contains(pattern) {
                if let range = text.range(of: pattern) {
                    var title = String(text[..<range.upperBound])
                    title = title.replacingOccurrences(of: "しなきゃ", with: "する")
                    title = title.replacingOccurrences(of: "しないと", with: "する")
                    title = title.replacingOccurrences(of: "しなければ", with: "する")
                    title = title.replacingOccurrences(of: "しなくては", with: "する")
                    return title
                }
            }
        }

        return nil
    }

    /// 対象タスクの検索クエリを抽出
    private func extractTargetTaskQuery(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        if match.numberOfRanges > 1 {
            let queryRange = match.range(at: 1)
            if let swiftRange = Range(queryRange, in: text) {
                var query = String(text[swiftRange])
                query = removeCommonSuffixes(from: query)
                return query.isEmpty ? nil : query
            }
        }

        return nil
    }

    /// 不要な接尾辞を削除
    private func removeCommonSuffixes(from text: String) -> String {
        let suffixes = ["を", "って", "が", "は", "の", "に", "と", "で"]
        var result = text

        for suffix in suffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// 優先度を抽出
    private func extractPriority(from text: String) -> PriorityLevel? {
        let highKeywords = ["重要", "急ぎ", "緊急", "至急", "大事", "優先", "必ず", "絶対"]
        let lowKeywords = ["後で", "いつか", "余裕", "暇なとき", "時間あれば"]

        for keyword in highKeywords {
            if text.contains(keyword) {
                return .high
            }
        }

        for keyword in lowKeywords {
            if text.contains(keyword) {
                return .low
            }
        }

        return nil
    }

    /// フィルタ用優先度を抽出
    private func extractFilterPriority(from text: String) -> PriorityLevel? {
        if text.contains("高優先度") || text.contains("高い優先度") || text.contains("重要な") {
            return .high
        }
        if text.contains("中優先度") || text.contains("普通の") {
            return .medium
        }
        if text.contains("低優先度") || text.contains("低い優先度") {
            return .low
        }
        return nil
    }

    /// カテゴリを抽出
    private func extractCategory(from text: String) -> TaskCategory? {
        for category in TaskCategory.allCases {
            for keyword in category.keywords {
                if text.contains(keyword) {
                    return category
                }
            }
        }
        return nil
    }

    /// 期限日時を抽出
    private func extractDueDate(from text: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        // 「今日」
        if text.contains("今日") || text.contains("きょう") {
            return calendar.startOfDay(for: now).addingTimeInterval(23 * 60 * 60 + 59 * 60)  // 23:59
        }

        // 「明日」
        if text.contains("明日") || text.contains("あした") || text.contains("あす") {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                return calendar.startOfDay(for: tomorrow).addingTimeInterval(23 * 60 * 60 + 59 * 60)
            }
        }

        // 「明後日」
        if text.contains("明後日") || text.contains("あさって") {
            if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: now) {
                return calendar.startOfDay(for: dayAfterTomorrow).addingTimeInterval(23 * 60 * 60 + 59 * 60)
            }
        }

        // 「今週」「今週中」
        if text.contains("今週") {
            // 今週の日曜日
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilSunday = 8 - weekday  // 日曜日までの日数
            if let sunday = calendar.date(byAdding: .day, value: daysUntilSunday, to: now) {
                return calendar.startOfDay(for: sunday).addingTimeInterval(23 * 60 * 60 + 59 * 60)
            }
        }

        // 「来週」
        if text.contains("来週") {
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
                // 来週の金曜日
                let weekday = calendar.component(.weekday, from: nextWeek)
                let daysUntilFriday = (6 - weekday + 7) % 7
                if let friday = calendar.date(byAdding: .day, value: daysUntilFriday, to: nextWeek) {
                    return calendar.startOfDay(for: friday).addingTimeInterval(23 * 60 * 60 + 59 * 60)
                }
            }
        }

        // 「今月」「今月中」
        if text.contains("今月") {
            if let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.startOfDay(for: now)) {
                return calendar.startOfDay(for: endOfMonth).addingTimeInterval(23 * 60 * 60 + 59 * 60)
            }
        }

        // 「X日後」パターン
        let daysLaterPattern = "(\\d+)日後"
        if let regex = try? NSRegularExpression(pattern: daysLaterPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1,
               let daysRange = Range(match.range(at: 1), in: text),
               let days = Int(text[daysRange]) {
                if let futureDate = calendar.date(byAdding: .day, value: days, to: now) {
                    return calendar.startOfDay(for: futureDate).addingTimeInterval(23 * 60 * 60 + 59 * 60)
                }
            }
        }

        // 「X月X日」パターン
        let datePattern = "(\\d{1,2})月(\\d{1,2})日"
        if let regex = try? NSRegularExpression(pattern: datePattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 2,
               let monthRange = Range(match.range(at: 1), in: text),
               let dayRange = Range(match.range(at: 2), in: text),
               let month = Int(text[monthRange]),
               let day = Int(text[dayRange]) {

                var components = calendar.dateComponents([.year], from: now)
                components.month = month
                components.day = day
                components.hour = 23
                components.minute = 59

                if var date = calendar.date(from: components) {
                    // 過去の日付の場合は来年に設定
                    if date < now {
                        components.year! += 1
                        date = calendar.date(from: components) ?? date
                    }
                    return date
                }
            }
        }

        return nil
    }
}
