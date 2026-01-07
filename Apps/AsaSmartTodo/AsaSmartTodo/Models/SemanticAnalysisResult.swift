//
//  SemanticAnalysisResult.swift
//  AsaSmartTodo
//
//  iOS 18 Foundation ModelsによるLLM意味分析の結果を保持
//  タスクの意味的複雑度、リスク、実行可能性を評価
//

import Foundation

#if canImport(LanguageModel)
import LanguageModel
#endif

// MARK: - SemanticAnalysisResult (共通データモデル)

/// LLM意味分析の結果を保持する構造体
///
/// タスクの意味的な複雑さ、リスク、実行可能性を数値化したデータモデルです。
/// iOS 18のFoundation Modelsから得られた分析結果を保存し、
/// ハイブリッド予測エンジンで活用されます。
struct SemanticAnalysisResult: Sendable, Codable {
    // MARK: - Properties

    /// 意味的複雑度（0.0-1.0）
    ///
    /// タスクの本質的な難しさや曖昧性を表します。
    /// - 0.0: 非常にシンプルで明確なタスク
    /// - 1.0: 非常に複雑で曖昧なタスク
    let semanticComplexity: Double

    /// リスクスコア（0.0-1.0）
    ///
    /// タスク完了の困難さや潜在的な障害を表します。
    /// - 0.0: リスクが非常に低い
    /// - 1.0: リスクが非常に高い
    let riskScore: Double

    /// 実行可能性スコア（0.0-1.0）
    ///
    /// タスクが現実的に完了可能かどうかを表します。
    /// - 0.0: 実行不可能または非常に困難
    /// - 1.0: 実行が容易で現実的
    let feasibilityScore: Double

    /// 推定所要時間（分）
    ///
    /// タスク完了に必要な時間の見積もり（分単位）。
    /// nilの場合は推定不可能または不明。
    let estimatedMinutes: Int?

    /// 分析で得られた洞察（3-5個）
    ///
    /// LLMが検出した特筆すべき点や注意事項のリスト。
    /// ユーザーに表示するための具体的なアドバイスや警告を含みます。
    let insights: [String]

    /// LLM信頼度（0.0-1.0）
    ///
    /// LLMが出力した分析結果の信頼度。
    /// JSON構造化出力（@Generable）を使用した場合は高信頼度（0.85前後）。
    let confidence: Double

    // MARK: - Computed Properties

    /// ハイブリッド予測用の統合スコア（0.0-1.0）
    ///
    /// 意味的複雑度、リスク、実行可能性を重み付けして統合したスコア。
    /// このスコアがルールベーススコアと組み合わされて最終予測に使用されます。
    ///
    /// ## 計算式
    /// ```
    /// combinedScore = semanticComplexity * 0.4
    ///               + riskScore * 0.3
    ///               + (1.0 - feasibilityScore) * 0.3
    /// ```
    ///
    /// - Note: feasibilityScoreは反転させて使用（実行困難なほど高スコア）
    var combinedScore: Double {
        let normalizedFeasibility = 1.0 - feasibilityScore  // 実行困難度に変換
        return (semanticComplexity * 0.4) + (riskScore * 0.3) + (normalizedFeasibility * 0.3)
    }

    // MARK: - Initializer

    init(
        semanticComplexity: Double,
        riskScore: Double,
        feasibilityScore: Double,
        estimatedMinutes: Int?,
        insights: [String],
        confidence: Double
    ) {
        // スコアを0.0-1.0の範囲にクランプ
        self.semanticComplexity = min(max(semanticComplexity, 0.0), 1.0)
        self.riskScore = min(max(riskScore, 0.0), 1.0)
        self.feasibilityScore = min(max(feasibilityScore, 0.0), 1.0)
        self.estimatedMinutes = estimatedMinutes
        self.insights = insights
        self.confidence = min(max(confidence, 0.0), 1.0)
    }
}

// MARK: - SemanticAnalysisOutput (iOS 18専用 - LanguageModel @Generable)

#if canImport(LanguageModel)

/// iOS 18 Foundation ModelsのJSON構造化出力用モデル
///
/// `@Generable`マクロを使用して、LLMに構造化されたJSON出力を要求します。
/// このモデルはLanguageModelSessionの`respond(to:generating:)`メソッドで使用されます。
@available(iOS 18.0, *)
@Generable
struct SemanticAnalysisOutput: Decodable {
    /// タスクの意味的複雑度を0.0-1.0で評価
    ///
    /// タスクの本質的な難しさ、曖昧性、多義性を考慮してください。
    /// シンプルで明確なタスクは0.0に近く、複雑で曖昧なタスクは1.0に近づきます。
    @Guide(description: "タスクの意味的複雑度を0.0-1.0で評価してください。0.0=非常にシンプル、1.0=非常に複雑")
    var semanticComplexity: Double

    /// タスクのリスクスコアを0.0-1.0で評価
    ///
    /// タスク完了の困難さ、潜在的な障害、依存関係による制約を考慮してください。
    /// リスクが低いタスクは0.0に近く、リスクが高いタスクは1.0に近づきます。
    @Guide(description: "タスクのリスクスコアを0.0-1.0で評価してください。0.0=リスクなし、1.0=高リスク")
    var riskScore: Double

    /// タスクの実行可能性を0.0-1.0で評価
    ///
    /// タスクが現実的に完了可能かどうか、必要なリソースが揃っているかを考慮してください。
    /// 実行不可能なタスクは0.0に近く、容易に実行可能なタスクは1.0に近づきます。
    @Guide(description: "タスクの実行可能性を0.0-1.0で評価してください。0.0=実行不可能、1.0=容易に実行可能")
    var feasibilityScore: Double

    /// タスクの推定所要時間（分単位）
    ///
    /// タスク完了に必要な時間を現実的に見積もってください。
    /// 不明な場合や推定できない場合は60分を返してください。
    @Guide(description: "タスクの推定所要時間を分単位で返してください（例: 30, 60, 120）")
    var estimatedMinutes: Int

    /// 分析で得られた洞察（3-5個）
    ///
    /// タスクに関する特筆すべき点、注意事項、リスク要因、成功のヒントなどを
    /// 具体的かつ実用的な形で提供してください。
    @Guide(description: "タスク分析から得られた洞察を3-5個のリストで返してください。具体的で実用的な内容にしてください", .count(3...5))
    var insights: [String]
}

#endif
