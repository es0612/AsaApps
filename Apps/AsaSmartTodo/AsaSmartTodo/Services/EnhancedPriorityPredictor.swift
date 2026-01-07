//
//  EnhancedPriorityPredictor.swift
//  AsaSmartTodo
//
//  ルールベースAIとLLM分析を統合したハイブリッド予測エンジン
//  ルールベース（40%）+ LLM分析（60%）の重み付け統合
//

import Foundation

/// ハイブリッド予測の拡張結果
///
/// ルールベース予測とLLM意味分析を組み合わせた予測結果を保持します。
struct EnhancedPredictionResult {
    // MARK: - Properties

    /// 推奨優先度
    let suggestedPriority: PriorityLevel

    /// 信頼度スコア（0.0-1.0）
    ///
    /// LLM使用時は75-98%、ルールベースのみは60-85%
    let confidenceScore: Double

    /// 予測理由のリスト
    ///
    /// ルールベース理由とLLM洞察を統合したリスト
    let reasons: [String]

    /// ルールベーススコア（0.0-1.0）
    let ruleBasedScore: Double

    /// LLM意味分析結果（iOS 18のみ）
    let semanticAnalysis: SemanticAnalysisResult?

    /// LLMを使用したかどうか
    let usedLLM: Bool

    // MARK: - Initializer

    init(
        suggestedPriority: PriorityLevel,
        confidenceScore: Double,
        reasons: [String],
        ruleBasedScore: Double,
        semanticAnalysis: SemanticAnalysisResult?,
        usedLLM: Bool
    ) {
        self.suggestedPriority = suggestedPriority
        self.confidenceScore = min(max(confidenceScore, 0.0), 1.0)
        self.reasons = reasons
        self.ruleBasedScore = min(max(ruleBasedScore, 0.0), 1.0)
        self.semanticAnalysis = semanticAnalysis
        self.usedLLM = usedLLM
    }
}

/// ルールベースAIとLLM分析を統合したハイブリッド予測エンジン
///
/// ## アーキテクチャ
/// ```
/// EnhancedPriorityPredictor
/// ├── TaskPriorityPredictor（ルールベース: 40%）
/// ├── TaskSemanticAnalyzer（LLM分析: 60%）
/// └── FoundationModelAvailability（iOS 18チェック）
/// ```
///
/// ## ハイブリッドスコア計算
/// ```
/// hybridScore = ruleBasedScore * 0.4 + llmScore * 0.6
/// ```
///
/// ## 使用例
/// ```swift
/// let predictor = EnhancedPriorityPredictor()
/// let task = SmartTask(title: "緊急の報告書作成", category: .work, dueDate: tomorrow)
///
/// let result = await predictor.predictPriority(for: task)
/// print("推奨優先度: \(result.suggestedPriority)")
/// print("信頼度: \(result.confidenceScore)")
/// print("LLM使用: \(result.usedLLM)")
/// ```
@MainActor
final class EnhancedPriorityPredictor {

    // MARK: - Dependencies

    private let ruleBasedPredictor: TaskPriorityPredictor
    private let semanticAnalyzer: TaskSemanticAnalyzer
    private let availabilityChecker: FoundationModelAvailability

    // MARK: - Configuration

    private let ruleBasedWeight: Double = 0.4  // ルールベースの重み（40%）
    private let llmWeight: Double = 0.6        // LLMの重み（60%）

    // MARK: - Initializer

    /// デフォルトの依存関係でEnhancedPriorityPredictorを初期化
    init() {
        self.ruleBasedPredictor = TaskPriorityPredictor()
        self.semanticAnalyzer = TaskSemanticAnalyzer()
        self.availabilityChecker = .shared
    }

    /// カスタム依存関係でEnhancedPriorityPredictorを初期化（テスト用）
    init(
        ruleBasedPredictor: TaskPriorityPredictor,
        semanticAnalyzer: TaskSemanticAnalyzer,
        availabilityChecker: FoundationModelAvailability
    ) {
        self.ruleBasedPredictor = ruleBasedPredictor
        self.semanticAnalyzer = semanticAnalyzer
        self.availabilityChecker = availabilityChecker
    }

    /// カスタムavailabilityCheckerでEnhancedPriorityPredictorを初期化（テスト用）
    init(availabilityChecker: FoundationModelAvailability) {
        self.ruleBasedPredictor = TaskPriorityPredictor()
        self.semanticAnalyzer = TaskSemanticAnalyzer(availabilityChecker: availabilityChecker)
        self.availabilityChecker = availabilityChecker
    }

    // MARK: - Public Methods

    /// タスクの優先度をハイブリッド予測
    ///
    /// iOS 18でFoundation Modelsが利用可能な場合は、ルールベース予測（40%）と
    /// LLM意味分析（60%）を統合したハイブリッド予測を実行します。
    ///
    /// iOS 17以下またはLLM利用不可の場合は、ルールベース予測のみを使用します。
    ///
    /// - Parameter task: 予測対象のSmartTaskオブジェクト
    /// - Returns: EnhancedPredictionResult（拡張予測結果）
    func predictPriority(for task: SmartTask) async -> EnhancedPredictionResult {
        // 1. ルールベース予測（常に実行）
        let ruleBasedResult = ruleBasedPredictor.predictPriority(for: task)
        let ruleBasedScore = convertPriorityToScore(ruleBasedResult.suggestedPriority)

        // 2. iOS 18可用性チェック
        guard await availabilityChecker.isAvailable() else {
            return fallbackToRuleBased(ruleBasedResult, ruleBasedScore)
        }

        // 3. LLM分析実行（iOS 18+のみ）
        do {
            let semanticResult = try await semanticAnalyzer.analyzeTask(task)
            let llmScore = semanticResult.combinedScore

            // 4. ハイブリッドスコア計算（40:60）
            let hybridScore = (ruleBasedScore * ruleBasedWeight) + (llmScore * llmWeight)

            // 5. スコアから優先度と信頼度を決定
            let (priority, confidence) = convertScoreToPriority(
                hybridScore,
                llmConfidence: semanticResult.confidence
            )

            return EnhancedPredictionResult(
                suggestedPriority: priority,
                confidenceScore: confidence,
                reasons: combineReasons(ruleBasedResult, semanticResult),
                ruleBasedScore: ruleBasedScore,
                semanticAnalysis: semanticResult,
                usedLLM: true
            )
        } catch {
            // LLM失敗時はルールベースフォールバック
            print("⚠️ LLM分析失敗、ルールベース予測にフォールバック: \(error.localizedDescription)")
            return fallbackToRuleBased(ruleBasedResult, ruleBasedScore)
        }
    }

    // MARK: - Private Methods

    /// 優先度をスコア（0.0-1.0）に変換
    ///
    /// - Parameter priority: PriorityLevel
    /// - Returns: 0.0-1.0の範囲のスコア
    private func convertPriorityToScore(_ priority: PriorityLevel) -> Double {
        switch priority {
        case .low:
            return 0.25
        case .medium:
            return 0.55
        case .high:
            return 0.85
        }
    }

    /// スコアから優先度と信頼度を決定
    ///
    /// ## スコアレンジと信頼度
    /// - 0.7以上: 高優先度、信頼度 min(score, 0.98)
    /// - 0.4-0.7: 中優先度、信頼度 0.75-0.90
    /// - 0.4未満: 低優先度、信頼度 0.60-0.80
    ///
    /// LLM信頼度を加味して+5-10%向上させます。
    ///
    /// - Parameters:
    ///   - score: ハイブリッドスコア（0.0-1.0）
    ///   - llmConfidence: LLMの信頼度（0.0-1.0）
    /// - Returns: (優先度, 信頼度)のタプル
    private func convertScoreToPriority(_ score: Double, llmConfidence: Double) -> (PriorityLevel, Double) {
        let priority: PriorityLevel
        var confidence: Double

        if score >= 0.7 {
            priority = .high
            confidence = min(score, 0.98)  // LLM使用時は最大98%
        } else if score >= 0.4 {
            priority = .medium
            confidence = 0.75 + (score - 0.4) * 0.5  // 0.75-0.90
        } else {
            priority = .low
            confidence = 0.60 + score * 0.5  // 0.60-0.80
        }

        // LLM信頼度を加味（+5-10%向上）
        confidence = min(confidence + (llmConfidence * 0.1), 0.98)

        return (priority, confidence)
    }

    /// ルールベース予測とLLM洞察を統合した理由リスト
    ///
    /// - Parameters:
    ///   - ruleBasedResult: ルールベース予測結果
    ///   - semanticResult: LLM意味分析結果
    /// - Returns: 統合された予測理由リスト
    private func combineReasons(_ ruleBasedResult: PredictionResult, _ semanticResult: SemanticAnalysisResult) -> [String] {
        var combinedReasons: [String] = []

        // ルールベース理由（最大3個）
        combinedReasons.append(contentsOf: ruleBasedResult.reasons.prefix(3))

        // LLM洞察（最大3個）
        combinedReasons.append(contentsOf: semanticResult.insights.prefix(3))

        return combinedReasons
    }

    /// ルールベース予測にフォールバック
    ///
    /// iOS 17以下またはLLM利用不可の場合の予測結果を生成します。
    ///
    /// - Parameters:
    ///   - ruleBasedResult: ルールベース予測結果
    ///   - ruleBasedScore: ルールベーススコア（0.0-1.0）
    /// - Returns: ルールベースのみのEnhancedPredictionResult
    private func fallbackToRuleBased(_ ruleBasedResult: PredictionResult, _ ruleBasedScore: Double) -> EnhancedPredictionResult {
        return EnhancedPredictionResult(
            suggestedPriority: ruleBasedResult.suggestedPriority,
            confidenceScore: ruleBasedResult.confidenceScore,
            reasons: ruleBasedResult.reasons,
            ruleBasedScore: ruleBasedScore,
            semanticAnalysis: nil,
            usedLLM: false
        )
    }
}
