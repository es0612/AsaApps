import SwiftUI
import AsaUIKit

struct AIInsightsView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @State private var insightsVM: AIInsightsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = insightsVM {
                    AIInsightsContent(viewModel: vm)
                } else {
                    ProgressView()
                        .onAppear {
                            initializeInsightsVM()
                        }
                }
            }
            .navigationTitle("AI洞察")
        }
    }

    private func initializeInsightsVM() {
        do {
            let container = try DataService.createContainer()
            let dataService = DataService(modelContainer: container)
            insightsVM = AIInsightsViewModel(dataService: dataService)
        } catch {
            print("Failed to initialize AIInsightsViewModel: \(error)")
        }
    }
}

// MARK: - AI Insights Content

struct AIInsightsContent: View {
    @Bindable var viewModel: AIInsightsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 分析ステータスカード
                AnalysisStatusCard(viewModel: viewModel)

                // アラートレベル表示
                if viewModel.hasAnalysisResult {
                    AlertLevelCard(alertLevel: viewModel.alertLevel)
                }

                // 予算予測カード
                if let prediction = viewModel.budgetPrediction {
                    BudgetPredictionCard(prediction: prediction)
                }

                // トップ洞察
                if !viewModel.topInsights.isEmpty {
                    InsightsListCard(insights: viewModel.topInsights)
                }

                // 異常検知サマリー
                if viewModel.anomalyCount > 0 {
                    AnomalyDetectionCard(
                        anomalyCount: viewModel.anomalyCount,
                        trend: viewModel.anomalyTrend
                    )
                }

                // 推奨事項
                if !viewModel.topRecommendations.isEmpty {
                    RecommendationsCard(recommendations: viewModel.topRecommendations)
                }

                // 予算推奨
                if let recommendation = viewModel.budgetRecommendation {
                    BudgetRecommendationCard(recommendation: recommendation)
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.runComprehensiveAnalysis()
        }
        .onAppear {
            if !viewModel.hasAnalysisResult {
                Task {
                    await viewModel.runQuickAnalysis()
                }
            }
        }
    }
}

// MARK: - Analysis Status Card

struct AnalysisStatusCard: View {
    @Bindable var viewModel: AIInsightsViewModel

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(AsaColors.coffeeBrown)

                    VStack(alignment: .leading) {
                        Text("AI分析")
                            .font(.headline)
                        Text(viewModel.formattedLastAnalyzedAt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if viewModel.isAnalyzing {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                await viewModel.runComprehensiveAnalysis()
                            }
                        } label: {
                            Text("分析実行")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AsaColors.coffeeBrown)
                                .cornerRadius(20)
                        }
                    }
                }

                if viewModel.hasAnalysisResult {
                    HStack {
                        ScoreIndicator(
                            title: "総合スコア",
                            score: viewModel.overallScore,
                            color: scoreColor(viewModel.overallScore)
                        )

                        Divider()

                        ScoreIndicator(
                            title: "信頼度",
                            score: viewModel.confidence,
                            color: .blue
                        )
                    }
                }
            }
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .red }
        if score >= 0.6 { return .orange }
        if score >= 0.4 { return .yellow }
        return .green
    }
}

// MARK: - Score Indicator

struct ScoreIndicator: View {
    let title: String
    let score: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Alert Level Card

struct AlertLevelCard: View {
    let alertLevel: AlertLevel

    var body: some View {
        HStack {
            Image(systemName: alertLevel.icon)
                .font(.title2)
                .foregroundColor(alertColor)

            VStack(alignment: .leading) {
                Text("現在のステータス")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(alertLevel.displayName)
                    .font(.headline)
                    .foregroundColor(alertColor)
            }

            Spacer()
        }
        .padding()
        .background(alertColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var alertColor: Color {
        switch alertLevel {
        case .critical: return .red
        case .warning: return .orange
        case .caution: return .yellow
        case .normal: return .green
        }
    }
}

// MARK: - Budget Prediction Card

struct BudgetPredictionCard: View {
    let prediction: BudgetPredictionResult

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AsaColors.coffeeBrown)
                    Text("予算予測")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                // 超過予測
                if prediction.willExceed {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("予算超過の可能性: \(prediction.probabilityPercentage)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // 予測詳細
                VStack(spacing: 12) {
                    PredictionRow(
                        title: "予測支出合計",
                        value: prediction.formattedPredictedTotal,
                        color: prediction.willExceed ? .red : .primary
                    )

                    if prediction.exceedanceAmount > 0 {
                        PredictionRow(
                            title: "予測超過額",
                            value: prediction.formattedExceedance,
                            color: .red
                        )
                    }

                    PredictionRow(
                        title: "残り日数",
                        value: "\(prediction.daysRemaining)日",
                        color: .primary
                    )

                    PredictionRow(
                        title: "推奨日次予算",
                        value: prediction.formattedRecommendedDaily,
                        color: AsaColors.coffeeBrown
                    )
                }

                // 洞察
                ForEach(prediction.insights, id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct PredictionRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Insights List Card

struct InsightsListCard: View {
    let insights: [AIInsight]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("AI洞察")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                ForEach(insights) { insight in
                    InsightRowView(insight: insight)
                }
            }
        }
    }
}

struct InsightRowView: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.category.icon)
                .foregroundColor(categoryColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if insight.actionable {
                    Text("対応推奨")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AsaColors.coffeeBrown)
                        .cornerRadius(4)
                }
            }

            Spacer()

            Text("\(Int(insight.importance * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch insight.category {
        case .spending: return .red
        case .saving: return .green
        case .pattern: return .blue
        case .budget: return .purple
        case .anomaly: return .orange
        }
    }
}

// MARK: - Anomaly Detection Card

struct AnomalyDetectionCard: View {
    let anomalyCount: Int
    let trend: AnomalyTrend?

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("異常検知")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("検出数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(anomalyCount)件")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if let trend = trend {
                        VStack(alignment: .trailing) {
                            HStack {
                                Image(systemName: trend.direction.icon)
                                Text(trend.message)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recommendations Card

struct RecommendationsCard: View {
    let recommendations: [BudgetRecommendation]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AsaColors.coffeeBrown)
                    Text("推奨事項")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                ForEach(recommendations) { recommendation in
                    RecommendationRowView(recommendation: recommendation)
                }
            }
        }
    }
}

struct RecommendationRowView: View {
    let recommendation: BudgetRecommendation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendation.type.icon)
                .foregroundColor(priorityColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let saving = recommendation.potentialSaving, saving > 0 {
                    Text("潜在的な節約: \(formatCurrency(saving))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Text(recommendation.priority.displayName)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Budget Recommendation Card

struct BudgetRecommendationCard: View {
    let recommendation: MonthlyBudgetRecommendation

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(AsaColors.coffeeBrown)
                    Text("予算推奨")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text(recommendation.recommendationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("推奨予算")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(recommendation.formattedRecommendation)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }

                    HStack {
                        Text("平均支出")
                        Spacer()
                        Text(recommendation.formattedAverageExpense)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if recommendation.potentialSavings > 0 {
                        HStack {
                            Text("想定貯蓄")
                            Spacer()
                            Text(recommendation.formattedPotentialSavings)
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }

                    HStack {
                        Text("信頼度")
                        Spacer()
                        Text(recommendation.confidencePercentage)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    AIInsightsView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
