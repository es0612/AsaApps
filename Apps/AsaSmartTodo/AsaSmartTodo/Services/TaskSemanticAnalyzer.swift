//
//  TaskSemanticAnalyzer.swift
//  AsaSmartTodo
//
//  iOS 18 Foundation Modelsを使用したタスク意味分析エンジン
//  タスクの意味的複雑度、リスク、実行可能性をLLMで評価
//

import Foundation

#if canImport(LanguageModel)
import LanguageModel
#endif

/// TaskSemanticAnalyzerのエラー型
enum SemanticAnalysisError: Error, LocalizedError {
    case modelUnavailable           // Foundation Modelsが利用不可
    case analysisTimeout            // 分析がタイムアウト
    case invalidResponse            // LLMからの応答が無効
    case scoringFailed              // スコア計算に失敗

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Foundation Modelsが利用できません。iOS 18以降が必要です。"
        case .analysisTimeout:
            return "AI分析がタイムアウトしました。"
        case .invalidResponse:
            return "AI分析の結果が無効です。"
        case .scoringFailed:
            return "スコア計算に失敗しました。"
        }
    }
}

/// iOS 18 Foundation Modelsを使用したタスク意味分析エンジン
///
/// タスクのタイトル、説明、カテゴリ、期限などの情報をLLMに送信し、
/// 意味的な複雑度、リスク、実行可能性を評価します。
///
/// ## 使用例
/// ```swift
/// let analyzer = TaskSemanticAnalyzer()
/// let task = SmartTask(title: "緊急の報告書作成", category: .work, dueDate: tomorrow)
///
/// do {
///     let result = try await analyzer.analyzeTask(task)
///     print("意味的複雑度: \(result.semanticComplexity)")
///     print("リスクスコア: \(result.riskScore)")
///     print("統合スコア: \(result.combinedScore)")
/// } catch {
///     print("分析エラー: \(error)")
/// }
/// ```
///
/// - Note: iOS 18以降でのみ動作します。iOS 17以下では`.modelUnavailable`エラーを返します。
@MainActor
final class TaskSemanticAnalyzer {

    // MARK: - Dependencies

    private let availabilityChecker: FoundationModelAvailability

    // MARK: - Initializer

    init(availabilityChecker: FoundationModelAvailability = .shared) {
        self.availabilityChecker = availabilityChecker
    }

    // MARK: - Public Methods

    /// タスクの意味分析を実行
    ///
    /// iOS 18のFoundation Modelsを使用して、タスクの意味的な複雑さ、リスク、
    /// 実行可能性を評価します。
    ///
    /// - Parameter task: 分析対象のSmartTaskオブジェクト
    /// - Returns: SemanticAnalysisResult（分析結果）
    /// - Throws: SemanticAnalysisError（モデル利用不可、タイムアウト等）
    func analyzeTask(_ task: SmartTask) async throws -> SemanticAnalysisResult {
        // 1. iOS 18可用性チェック
        guard await availabilityChecker.isAvailable() else {
            throw SemanticAnalysisError.modelUnavailable
        }

        #if canImport(LanguageModel)
        if #available(iOS 18.0, *) {
            return try await performLLMAnalysis(task)
        } else {
            throw SemanticAnalysisError.modelUnavailable
        }
        #else
        throw SemanticAnalysisError.modelUnavailable
        #endif
    }

    // MARK: - Private Methods (iOS 18+)

    #if canImport(LanguageModel)
    @available(iOS 18.0, *)
    private func performLLMAnalysis(_ task: SmartTask) async throws -> SemanticAnalysisResult {
        // 2. プロンプト構築
        let prompt = buildPrompt(for: task)

        // 3. LanguageModelSession作成
        let session = LanguageModelSession(
            instructions: """
            あなたはタスク管理の専門家です。
            タスク情報を分析し、以下の観点で客観的に評価してください：

            1. **意味的複雑度**: タスクの本質的な難しさ、曖昧性、多義性
            2. **リスクスコア**: 完了の困難さ、潜在的な障害、依存関係
            3. **実行可能性**: タスクが現実的に完了可能かどうか
            4. **推定所要時間**: 分単位での現実的な見積もり
            5. **洞察**: 特筆すべき点、注意事項、リスク要因、成功のヒント

            評価は数値（0.0-1.0）で行い、洞察は3-5個の具体的かつ実用的な内容で提供してください。
            """
        )

        do {
            // 4. LLM実行（JSON構造化出力）
            let output = try await session.respond(
                to: prompt,
                generating: SemanticAnalysisOutput.self
            )

            // 5. SemanticAnalysisOutputをSemanticAnalysisResultに変換
            return convertToResult(output)

        } catch {
            // LLMエラーをSemanticAnalysisErrorに変換
            if error.localizedDescription.contains("timeout") {
                throw SemanticAnalysisError.analysisTimeout
            } else {
                throw SemanticAnalysisError.invalidResponse
            }
        }
    }

    @available(iOS 18.0, *)
    private func buildPrompt(for task: SmartTask) -> String {
        // タスク情報を日本語で構造化
        var promptParts: [String] = []

        promptParts.append("【タスク情報】")
        promptParts.append("タイトル: \(task.title)")

        if let description = task.taskDescription, !description.isEmpty {
            promptParts.append("説明: \(description)")
        } else {
            promptParts.append("説明: （なし）")
        }

        promptParts.append("カテゴリ: \(task.category.rawValue)")

        if let daysUntilDue = task.daysUntilDue {
            if daysUntilDue < 0 {
                promptParts.append("期限: 期限切れ（\(-daysUntilDue)日前）")
            } else if daysUntilDue == 0 {
                promptParts.append("期限: 今日")
            } else if daysUntilDue == 1 {
                promptParts.append("期限: 明日")
            } else {
                promptParts.append("期限: \(daysUntilDue)日後")
            }
        } else {
            promptParts.append("期限: 未設定")
        }

        promptParts.append("ユーザー設定優先度: \(task.userPriority.rawValue)")

        promptParts.append("")
        promptParts.append("上記のタスクを分析し、以下の観点で評価してください：")
        promptParts.append("1. 意味的複雑度: タスクの本質的な難しさ、曖昧性（0.0-1.0）")
        promptParts.append("2. リスクスコア: 完了の困難さ、潜在的な障害（0.0-1.0）")
        promptParts.append("3. 実行可能性: タスクが現実的に完了可能か（0.0-1.0）")
        promptParts.append("4. 推定所要時間: 分単位での見積もり")
        promptParts.append("5. 洞察: 特筆すべき点、注意事項（3-5個）")

        return promptParts.joined(separator: "\n")
    }

    @available(iOS 18.0, *)
    private func convertToResult(_ output: SemanticAnalysisOutput) -> SemanticAnalysisResult {
        return SemanticAnalysisResult(
            semanticComplexity: output.semanticComplexity,
            riskScore: output.riskScore,
            feasibilityScore: output.feasibilityScore,
            estimatedMinutes: output.estimatedMinutes > 0 ? output.estimatedMinutes : nil,
            insights: output.insights,
            confidence: 0.85  // JSON構造化出力は高信頼度
        )
    }
    #endif
}
