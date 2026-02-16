//
//  PapaHubAIService.swift
//  AsaPapaHub
//
//  Foundation Modelsを使用したAIブリーフィングサービス
//  オンデバイスLLMで朝のブリーフィングや週間サマリーを生成
//

import Foundation
import FoundationModels
import AsaPapaHubKit

// MARK: - PapaHubAIService

/// Foundation Models を使用した AI ブリーフィングサービス
@MainActor
@Observable
final class PapaHubAIService {
    // MARK: - Properties

    /// LLMセッション
    private var session: LanguageModelSession?

    /// 処理中フラグ
    private(set) var isProcessing = false

    /// セッション準備完了フラグ
    private(set) var isSessionReady = false

    /// エラーメッセージ
    private(set) var lastError: String?

    // MARK: - Initialization

    init() {
        Task {
            await prepareSession()
        }
    }

    // MARK: - Session Management

    /// セッションを準備（プレウォーム）
    func prepareSession() async {
        do {
            guard SystemLanguageModel.default.availability == .available else {
                lastError = "このデバイスではFoundation Modelsが利用できません"
                return
            }

            session = LanguageModelSession()
            try await session?.prewarm()
            isSessionReady = true
            lastError = nil
        } catch {
            lastError = "セッションの準備に失敗しました: \(error.localizedDescription)"
            isSessionReady = false
        }
    }

    // MARK: - Morning Briefing

    /// 朝のブリーフィングを生成
    /// - Parameter dashboard: 今日のダッシュボードデータ
    /// - Returns: AI生成されたブリーフィング
    func generateMorningBriefing(dashboard: HubDashboard) async throws -> MorningBriefingGenerable {
        guard let session else {
            throw PapaHubAIError.sessionNotReady
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = buildMorningBriefingPrompt(dashboard: dashboard)

        let response = try await session.respond(
            to: prompt,
            generating: MorningBriefingGenerable.self
        )

        return response.content
    }

    /// 朝のブリーフィングをストリーミング生成
    /// - Parameter dashboard: 今日のダッシュボードデータ
    /// - Returns: ストリーミングレスポンス
    func streamMorningBriefing(
        dashboard: HubDashboard
    ) -> AsyncThrowingStream<MorningBriefingGenerable.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard let session = self.session else {
                    continuation.finish(throwing: PapaHubAIError.sessionNotReady)
                    return
                }

                self.isProcessing = true

                let prompt = self.buildMorningBriefingPrompt(dashboard: dashboard)

                do {
                    for try await partial in session.streamResponse(
                        to: prompt,
                        generating: MorningBriefingGenerable.self
                    ) {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                self.isProcessing = false
            }
        }
    }

    // MARK: - Weekly Summary

    /// 週間サマリーを生成
    /// - Parameter dashboards: 週間のダッシュボードデータ配列
    /// - Returns: AI生成された週間サマリー
    func generateWeeklySummary(dashboards: [HubDashboard]) async throws -> WeeklySummaryReport {
        guard let session else {
            throw PapaHubAIError.sessionNotReady
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = buildWeeklySummaryPrompt(dashboards: dashboards)

        let response = try await session.respond(
            to: prompt,
            generating: WeeklySummaryReport.self
        )

        return response.content
    }

    // MARK: - Natural Language Search

    /// 自然言語検索を実行
    /// - Parameter query: 検索クエリ
    /// - Returns: AI生成された検索結果
    func searchNaturalLanguage(query: String) async throws -> AISearchResult {
        guard let session else {
            throw PapaHubAIError.sessionNotReady
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        ユーザーがパパハブ（家族パパの統合ライフ管理アプリ）で以下の検索をしました:

        検索クエリ: \(query)

        このアプリは6つのライフドメインを管理します:
        - 朝活（早起き、朝のルーティン）
        - 健康（歩数、睡眠、運動）
        - 家族（子供の成長、家族イベント）
        - 資産（資産管理、節約）
        - 地域（コミュニティ活動、近所付き合い）
        - 学習（読書、スキルアップ）

        検索クエリに対して:
        1. 簡潔で役立つ回答を日本語で提供してください
        2. 関連するライフドメインを特定してください
        3. 実行可能なアクションを提案してください
        """

        let response = try await session.respond(
            to: prompt,
            generating: AISearchResult.self
        )

        return response.content
    }

    // MARK: - Fallback (AI非対応デバイス用)

    /// ヒューリスティックで朝のブリーフィングを生成（AI非対応時のフォールバック）
    func generateFallbackBriefing(dashboard: HubDashboard) -> MorningBriefingGenerable {
        let score = dashboard.morningScore
        let steps = dashboard.stepsCount
        let sleep = dashboard.sleepHours

        let greeting: String
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            greeting = "素晴らしい早起きですね！静かな朝の時間を大切に。"
        } else if hour < 9 {
            greeting = "おはようございます！今日も良い一日にしましょう。"
        } else {
            greeting = "お疲れさまです！今日の調子はいかがですか？"
        }

        let scheduleOverview: String
        let domains = dashboard.activeDomains
        if domains.isEmpty {
            scheduleOverview = "今日はまだ活動が記録されていません。新しい一日を始めましょう！"
        } else {
            let domainNames = domains.map(\.displayName).joined(separator: "、")
            scheduleOverview = "今日は\(domainNames)の活動が予定されています。"
        }

        let healthAdvice: String
        if sleep < 6.0 {
            healthAdvice = "睡眠時間が少し短めです。今夜は早めに休みましょう。"
        } else if steps > 8000 {
            healthAdvice = "よく歩いていますね！この調子で健康的な生活を続けましょう。"
        } else {
            healthAdvice = "適度な運動を心がけて、心身ともに健やかに過ごしましょう。"
        }

        let motivationalMessage: String
        if score >= 80 {
            motivationalMessage = "素晴らしいスコアです！あなたの努力が実を結んでいます。"
        } else if score >= 50 {
            motivationalMessage = "着実に前進しています。一歩一歩が大きな成長につながります。"
        } else {
            motivationalMessage = "今日からでも遅くありません。小さな一歩から始めましょう！"
        }

        return MorningBriefingGenerable(
            greeting: greeting,
            scheduleOverview: scheduleOverview,
            healthAdvice: healthAdvice,
            motivationalMessage: motivationalMessage
        )
    }

    /// ヒューリスティックで週間サマリーを生成（AI非対応時のフォールバック）
    func generateFallbackWeeklySummary(dashboards: [HubDashboard]) -> WeeklySummaryReport {
        let avgScore = dashboards.isEmpty ? 0
            : dashboards.map(\.morningScore).reduce(0, +) / dashboards.count
        let totalSteps = dashboards.map(\.stepsCount).reduce(0, +)
        let avgSleep = dashboards.isEmpty ? 0.0
            : dashboards.map(\.sleepHours).reduce(0.0, +) / Double(dashboards.count)

        let summary = "今週は\(dashboards.count)日間の記録があり、平均朝活スコアは\(avgScore)点でした。" +
            "合計\(totalSteps)歩を歩き、平均睡眠時間は\(String(format: "%.1f", avgSleep))時間でした。"

        var highlights: [String] = []
        if let best = dashboards.max(by: { $0.morningScore < $1.morningScore }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "E曜日"
            formatter.locale = Locale(identifier: "ja_JP")
            highlights.append("\(formatter.string(from: best.date))に最高スコア\(best.morningScore)点を達成")
        }
        if totalSteps > 50000 {
            highlights.append("週間合計\(totalSteps)歩を達成")
        }
        if avgSleep >= 7.0 {
            highlights.append("平均睡眠時間\(String(format: "%.1f", avgSleep))時間を確保")
        }
        if highlights.isEmpty {
            highlights.append("今週も毎日の記録を続けています")
        }

        let suggestions = [
            "朝の時間を有効活用して、自分磨きの時間を確保しましょう",
            "家族との時間も大切にしながら、バランスの取れた生活を目指しましょう",
        ]

        let encouragement = avgScore >= 70
            ? "素晴らしい一週間でした！来週もこの調子で頑張りましょう！"
            : "来週はもっと良い一週間にできるはず。応援しています！"

        return WeeklySummaryReport(
            summary: summary,
            highlights: highlights,
            suggestions: suggestions,
            encouragement: encouragement
        )
    }

    // MARK: - Private Methods

    /// 朝のブリーフィング用プロンプトを構築
    private func buildMorningBriefingPrompt(dashboard: HubDashboard) -> String {
        let domains = dashboard.activeDomains.map(\.displayName).joined(separator: "、")
        let mood = dashboard.moodRawValue ?? "未記録"

        return """
        あなたは「パパハブ」の朝活AIアシスタントです。
        朝活パパエンジニアに向けた、温かみのある朝のブリーフィングを生成してください。

        今日のデータ:
        - 朝活スコア: \(dashboard.morningScore)点
        - 歩数: \(dashboard.stepsCount)歩
        - 睡眠時間: \(String(format: "%.1f", dashboard.sleepHours))時間
        - 気分: \(mood)
        - 進捗: \(String(format: "%.0f", dashboard.overallProgress * 100))%
        - アクティブドメイン: \(domains.isEmpty ? "なし" : domains)

        注意事項:
        - 日本語で温かみのある言葉を使ってください
        - パパとしての頑張りを認める表現を含めてください
        - データに基づいた具体的なアドバイスを提供してください
        - 各フィールドは2-3文程度で簡潔にまとめてください
        """
    }

    /// 週間サマリー用プロンプトを構築
    private func buildWeeklySummaryPrompt(dashboards: [HubDashboard]) -> String {
        let avgScore = dashboards.isEmpty ? 0
            : dashboards.map(\.morningScore).reduce(0, +) / dashboards.count
        let totalSteps = dashboards.map(\.stepsCount).reduce(0, +)
        let avgSleep = dashboards.isEmpty ? 0.0
            : dashboards.map(\.sleepHours).reduce(0.0, +) / Double(dashboards.count)
        let daysRecorded = dashboards.count

        return """
        あなたは「パパハブ」の週間レポートAIアシスタントです。
        朝活パパエンジニアの一週間を総括するレポートを生成してください。

        今週のデータ:
        - 記録日数: \(daysRecorded)日
        - 平均朝活スコア: \(avgScore)点
        - 合計歩数: \(totalSteps)歩
        - 平均睡眠時間: \(String(format: "%.1f", avgSleep))時間

        注意事項:
        - 日本語で温かみのある言葉を使ってください
        - 頑張りを認めつつ、具体的な改善提案も含めてください
        - ハイライトは特に印象的な成果に焦点を当ててください
        - 来週への提案は実行可能な内容にしてください
        """
    }
}

// MARK: - PapaHubAIError

/// PapaHubAIServiceのエラー
enum PapaHubAIError: Error, LocalizedError {
    case sessionNotReady
    case deviceNotSupported
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .sessionNotReady:
            return "AIセッションが準備できていません"
        case .deviceNotSupported:
            return "このデバイスではAI機能を利用できません"
        case .generationFailed(let message):
            return "生成に失敗しました: \(message)"
        }
    }
}
