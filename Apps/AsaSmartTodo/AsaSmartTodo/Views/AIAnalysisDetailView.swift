//
//  AIAnalysisDetailView.swift
//  AsaSmartTodo
//
//  AI予測の詳細分析結果を表示するビュー
//  ルールベーススコア、LLM分析結果、ハイブリッド予測の内訳を可視化
//

import SwiftUI
import AsaUIKit

/// AI予測の詳細分析結果を表示するビュー
///
/// ハイブリッドAI予測の内訳を視覚的に表示します：
/// - 推奨優先度と信頼度スコア
/// - 予測理由リスト（ルールベース + LLM洞察）
/// - LLM意味分析の詳細（iOS 18のみ）
///
/// ## 使用例
/// ```swift
/// .sheet(isPresented: $showingAIDetail) {
///     AIAnalysisDetailView(prediction: enhancedPrediction, task: selectedTask)
/// }
/// ```
struct AIAnalysisDetailView: View {
    // MARK: - Properties

    let prediction: EnhancedPredictionResult
    let task: SmartTask

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダーバッジ
                    headerBadge

                    // サマリーセクション
                    summarySection

                    // 予測理由セクション
                    reasonsSection

                    // LLM分析セクション（iOS 18のみ）
                    if prediction.usedLLM, let semanticAnalysis = prediction.semanticAnalysis {
                        llmAnalysisSection(semanticAnalysis)
                    }

                    // スコア内訳セクション
                    scoreBreakdownSection
                }
                .padding()
            }
            .navigationTitle("AI予測分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    /// ヘッダーバッジ（iOS 18 LLM使用時）
    private var headerBadge: some View {
        Group {
            if prediction.usedLLM {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("iOS 18 高度なAI分析")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text("ルールベース分析")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AsaColors.coffeeBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AsaColors.softCream)
                .cornerRadius(12)
            }
        }
    }

    /// サマリーセクション
    private var summarySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI予測サマリー")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Divider()

                // 推奨優先度
                HStack {
                    Text("推奨優先度:")
                        .foregroundColor(AsaColors.mutedSage)
                    Spacer()
                    priorityBadge(prediction.suggestedPriority)
                }

                // 信頼度スコア
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("信頼度:")
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text("\(Int(prediction.confidenceScore * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(confidenceColor(prediction.confidenceScore))
                    }

                    // 信頼度プログレスバー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AsaColors.softCream)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(confidenceColor(prediction.confidenceScore))
                                .frame(
                                    width: geometry.size.width * prediction.confidenceScore,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }

                // タスク情報
                VStack(alignment: .leading, spacing: 4) {
                    Text("分析対象タスク:")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text(task.title)
                        .font(.body)
                        .foregroundColor(AsaColors.darkSlate)
                }
            }
            .padding()
        }
    }

    /// 予測理由セクション
    private var reasonsSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("予測理由")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Divider()

                ForEach(Array(prediction.reasons.enumerated()), id: \.offset) { index, reason in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AsaColors.coffeeBrown)
                            .frame(width: 20, alignment: .leading)

                        Text(reason)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if index < prediction.reasons.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
        }
    }

    /// LLM分析セクション（iOS 18のみ）
    private func llmAnalysisSection(_ analysis: SemanticAnalysisResult) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("LLM意味分析")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                }

                Divider()

                // 意味的複雑度
                scoreRow(
                    title: "意味的複雑度",
                    score: analysis.semanticComplexity,
                    description: "タスクの本質的な難しさ、曖昧性"
                )

                Divider()

                // リスクスコア
                scoreRow(
                    title: "リスクスコア",
                    score: analysis.riskScore,
                    description: "完了の困難さ、潜在的な障害"
                )

                Divider()

                // 実行可能性
                scoreRow(
                    title: "実行可能性",
                    score: analysis.feasibilityScore,
                    description: "現実的に完了可能かどうか"
                )

                // 推定所要時間
                if let estimatedMinutes = analysis.estimatedMinutes {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("推定所要時間")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AsaColors.darkSlate)
                            Text("LLMによる時間見積もり")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                        Spacer()
                        Text("\(estimatedMinutes)分")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                // LLM洞察
                if !analysis.insights.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("LLM洞察")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AsaColors.darkSlate)

                        ForEach(Array(analysis.insights.enumerated()), id: \.offset) { index, insight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)

                                Text(insight)
                                    .font(.caption)
                                    .foregroundColor(AsaColors.darkSlate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    /// スコア内訳セクション
    private var scoreBreakdownSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("スコア内訳")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Divider()

                if prediction.usedLLM {
                    // ハイブリッドスコア内訳
                    VStack(alignment: .leading, spacing: 12) {
                        scoreBreakdownRow(
                            title: "ルールベース",
                            weight: "40%",
                            score: prediction.ruleBasedScore
                        )

                        scoreBreakdownRow(
                            title: "LLM分析",
                            weight: "60%",
                            score: prediction.semanticAnalysis?.combinedScore ?? 0.0
                        )

                        Divider()

                        HStack {
                            Text("統合スコア")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.darkSlate)
                            Spacer()
                            Text(String(format: "%.0f%%", (prediction.ruleBasedScore * 0.4 + (prediction.semanticAnalysis?.combinedScore ?? 0.0) * 0.6) * 100))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                } else {
                    // ルールベースのみ
                    HStack {
                        Text("ルールベーススコア")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AsaColors.darkSlate)
                        Spacer()
                        Text(String(format: "%.0f%%", prediction.ruleBasedScore * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    /// 優先度バッジ
    private func priorityBadge(_ priority: PriorityLevel) -> some View {
        Text(priority.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(priorityColor(priority))
            .cornerRadius(8)
    }

    /// 優先度カラー
    private func priorityColor(_ priority: PriorityLevel) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }

    /// 信頼度カラー
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.85 {
            return .green
        } else if confidence >= 0.70 {
            return .orange
        } else {
            return .red
        }
    }

    /// スコア行
    private func scoreRow(title: String, score: Double, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.darkSlate)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                Spacer()
                Text(String(format: "%.0f%%", score * 100))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            // スコアバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AsaColors.softCream)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreBarColor(score))
                        .frame(width: geometry.size.width * score, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    /// スコアバーカラー
    private func scoreBarColor(_ score: Double) -> Color {
        if score >= 0.7 {
            return .red
        } else if score >= 0.4 {
            return .orange
        } else {
            return .green
        }
    }

    /// スコア内訳行
    private func scoreBreakdownRow(title: String, weight: String, score: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.darkSlate)
                Text("重み: \(weight)")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
            Spacer()
            Text(String(format: "%.0f%%", score * 100))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(AsaColors.coffeeBrown)
        }
    }
}

// MARK: - Preview

#Preview {
    AIAnalysisDetailView(
        prediction: EnhancedPredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.92,
            reasons: [
                "期限が近い（明日まで）",
                "仕事カテゴリのタスク",
                "タスクタイトルが複雑（高難易度）",
                "LLM分析: 緊急性が高く、リスクが中程度",
                "LLM分析: 実行可能性が高い"
            ],
            ruleBasedScore: 0.85,
            semanticAnalysis: SemanticAnalysisResult(
                semanticComplexity: 0.75,
                riskScore: 0.55,
                feasibilityScore: 0.80,
                estimatedMinutes: 120,
                insights: [
                    "緊急性が高いため、優先的に取り組むべき",
                    "複雑なタスクのため、十分な時間を確保する必要がある",
                    "依存関係がないため、すぐに着手可能"
                ],
                confidence: 0.90
            ),
            usedLLM: true
        ),
        task: SmartTask(
            title: "緊急の報告書作成",
            description: "プレゼン資料を完成させる",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )
    )
}
