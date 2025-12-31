//
//  AnalyticsView.swift
//  AsaSmartTodo
//
//  メイン分析ビュー
//  生産性ダッシュボードとAI精度トラッキング
//

import SwiftUI
import AsaUIKit

struct AnalyticsView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section 1: 今日のサマリー
                    todaySummarySection

                    // Section 2: AI予測精度カード
                    aiAccuracyCard

                    // Section 3: 24時間生産性チャート（プレースホルダー）
                    productivityChartSection

                    // Section 4: 週次レポートカード
                    weeklyReportCard
                }
                .padding()
            }
            .navigationTitle("分析")
            .refreshable {
                viewModel.loadAnalytics()
            }
            .onAppear {
                viewModel.loadAnalytics()
            }
        }
    }

    // MARK: - Today Summary Section

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("今日のサマリー")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text(formatDate(Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let today = viewModel.todayAnalytics {
                HStack(spacing: 16) {
                    // 完了率
                    summaryMetric(
                        icon: "checkmark.circle.fill",
                        label: "完了率",
                        value: viewModel.formatPercentage(today.completionRate),
                        color: .green
                    )

                    Divider()
                        .frame(height: 50)

                    // 朝活スコア
                    summaryMetric(
                        icon: "sunrise.fill",
                        label: "朝活スコア",
                        value: viewModel.formatPercentage(today.earlyMorningProductivityScore),
                        color: AsaColors.coffeeBrown
                    )

                    Divider()
                        .frame(height: 50)

                    // 期限切れ
                    summaryMetric(
                        icon: "exclamationmark.triangle.fill",
                        label: "期限切れ",
                        value: "\(today.overdueTasks)件",
                        color: today.overdueTasks > 0 ? .red : .green
                    )
                }
                .padding()
                .background(AsaColors.softCream.opacity(0.3))
                .cornerRadius(12)
            } else {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    // MARK: - AI Accuracy Card

    private var aiAccuracyCard: some View {
        NavigationLink {
            AIInsightsView(viewModel: viewModel)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("AI予測精度")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                if let today = viewModel.todayAnalytics, today.totalPredictions > 0 {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("採用率")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(viewModel.formatPercentage(today.aiAcceptanceRate))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("信頼度")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(viewModel.formatPercentage(today.averageConfidence))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.mocha)
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("総予測数")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(today.totalPredictions)回")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                } else {
                    Text("まだAI予測データがありません")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Productivity Chart Section

    private var productivityChartSection: some View {
        ProductivityChartView(hourlyData: viewModel.hourlyChartData)
    }

    // MARK: - Weekly Report Card

    private var weeklyReportCard: some View {
        NavigationLink {
            WeeklySummaryView(viewModel: viewModel)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(AsaColors.mutedSage)

                    Text("週次レポート")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("平均完了率")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.formatPercentage(viewModel.weeklyCompletionRate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("AI採用率")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.formatPercentage(viewModel.weeklyAIAcceptanceRate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("朝活スコア")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.formatPercentage(viewModel.weeklyEarlyMorningScore))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.mocha)
                    }
                }
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    private func summaryMetric(icon: String, label: String, value: String, color: Color) -> some View {
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
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
