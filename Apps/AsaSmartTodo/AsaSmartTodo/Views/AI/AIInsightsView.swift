//
//  AIInsightsView.swift
//  AsaSmartTodo
//
//  AI予測精度ダッシュボード
//  週間トレンドと精度詳細を表示
//

import SwiftUI
import Charts
import AsaUIKit

struct AIInsightsView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Section 1: 今日のサマリー
                todaySummarySection

                // Section 2: 週間トレンドチャート
                weeklyTrendChart

                // Section 3: 精度詳細
                accuracyDetailSection

                // Section 4: 改善提案
                improvementSuggestions
            }
            .padding()
        }
        .navigationTitle("AI予測精度")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadAnalytics()
        }
    }

    // MARK: - Today Summary Section

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("今日のAI精度")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            if let today = viewModel.todayAnalytics, today.totalPredictions > 0 {
                HStack(spacing: 12) {
                    // 採用率
                    metricCard(
                        icon: "checkmark.circle.fill",
                        label: "採用率",
                        value: viewModel.formatPercentage(today.aiAcceptanceRate),
                        color: accuracyColor(today.aiAcceptanceRate)
                    )

                    // 平均信頼度
                    metricCard(
                        icon: "star.fill",
                        label: "平均信頼度",
                        value: viewModel.formatPercentage(today.averageConfidence),
                        color: AsaColors.mocha
                    )

                    // 総予測数
                    metricCard(
                        icon: "number",
                        label: "総予測数",
                        value: "\(today.totalPredictions)回",
                        color: AsaColors.darkSlate
                    )
                }
            } else {
                emptyStateView
            }
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Weekly Trend Chart

    private var weeklyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("週間トレンド")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            if !viewModel.aiAccuracyTrend.isEmpty {
                Chart {
                    ForEach(viewModel.aiAccuracyTrend) { data in
                        // 採用率
                        LineMark(
                            x: .value("日付", data.dateLabel),
                            y: .value("採用率", data.acceptanceRate * 100)
                        )
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(60)

                        // 信頼度
                        LineMark(
                            x: .value("日付", data.dateLabel),
                            y: .value("信頼度", data.averageConfidence * 100)
                        )
                        .foregroundStyle(AsaColors.mocha)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(60)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(intValue)%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        if let label = value.as(String.self) {
                            AxisValueLabel {
                                Text(label)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, spacing: 12) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AsaColors.coffeeBrown)
                                .frame(width: 12, height: 12)

                            Text("採用率")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(AsaColors.mocha)
                                .frame(width: 12, height: 12)

                            Text("信頼度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                emptyStateView
            }
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Accuracy Detail Section

    private var accuracyDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title2)
                    .foregroundColor(AsaColors.mutedSage)

                Text("精度詳細")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            // 週間統計
            VStack(spacing: 12) {
                detailRow(
                    label: "週間採用回数",
                    value: "\(weeklyAcceptedPredictions)回",
                    icon: "checkmark.circle",
                    color: .green
                )

                Divider()

                detailRow(
                    label: "週間却下回数",
                    value: "\(weeklyRejectedPredictions)回",
                    icon: "xmark.circle",
                    color: .red
                )

                Divider()

                detailRow(
                    label: "週間平均採用率",
                    value: viewModel.formatPercentage(viewModel.weeklyAIAcceptanceRate),
                    icon: "percent",
                    color: AsaColors.coffeeBrown
                )

                Divider()

                detailRow(
                    label: "週間平均信頼度",
                    value: viewModel.formatPercentage(viewModel.weeklyAverageConfidence),
                    icon: "star.fill",
                    color: AsaColors.mocha
                )
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Improvement Suggestions

    private var improvementSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)

                Text("改善提案")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundColor(AsaColors.coffeeBrown)

                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Helper Views

    private func metricCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }

    private func detailRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("まだデータがありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Computed Properties

    private var weeklyAcceptedPredictions: Int {
        viewModel.weeklyAnalytics.reduce(0) { $0 + $1.acceptedPredictions }
    }

    private var weeklyRejectedPredictions: Int {
        viewModel.weeklyAnalytics.reduce(0) { $0 + $1.rejectedPredictions }
    }

    private var suggestions: [String] {
        let acceptanceRate = viewModel.weeklyAIAcceptanceRate

        if acceptanceRate >= 0.8 {
            return [
                "素晴らしい！AI予測の精度が高く維持されています",
                "引き続きフィードバックを提供し、精度を保ちましょう",
                "新しいタスクカテゴリでも同様の精度を目指しましょう"
            ]
        } else if acceptanceRate >= 0.6 {
            return [
                "AI予測の精度は良好です",
                "特定のカテゴリでの精度を確認してみましょう",
                "フィードバックを続けることで、さらに精度が向上します"
            ]
        } else if acceptanceRate >= 0.4 {
            return [
                "AI予測の精度にばらつきがあるようです",
                "タスクの説明をより詳細に記入すると精度が上がります",
                "期限を設定することで、優先度予測の精度が向上します"
            ]
        } else {
            return [
                "AI予測の精度向上の余地があります",
                "タスク入力時に、タイトルと説明を具体的に記入しましょう",
                "期限とカテゴリを正確に設定することが重要です",
                "フィードバックを積極的に提供して、AIの学習を助けましょう"
            ]
        }
    }

    private func accuracyColor(_ rate: Double) -> Color {
        switch rate {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return AsaColors.coffeeBrown
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
}
