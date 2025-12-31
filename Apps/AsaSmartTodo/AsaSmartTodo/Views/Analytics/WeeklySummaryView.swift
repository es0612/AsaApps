//
//  WeeklySummaryView.swift
//  AsaSmartTodo
//
//  週次サマリービュー
//  7日間の生産性とAI精度の詳細分析
//

import SwiftUI
import Charts
import AsaUIKit

struct WeeklySummaryView: View {
    @Bindable var viewModel: AnalyticsViewModel

    @State private var selectedDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 期間ヘッダー
                periodHeader

                // サマリーカード
                summaryCards

                // 週間トレンドチャート
                weeklyTrendChart

                // 日別テーブル
                dailyTable
            }
            .padding()
        }
        .navigationTitle("週次レポート")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadAnalytics(for: .week)
        }
    }

    // MARK: - Period Header

    private var periodHeader: some View {
        HStack {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundColor(AsaColors.mutedSage)

            Text(periodText)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Menu {
                Button {
                    viewModel.loadAnalytics(for: .week)
                } label: {
                    Label("週間", systemImage: "calendar")
                }

                Button {
                    viewModel.loadAnalytics(for: .month)
                } label: {
                    Label("月間", systemImage: "calendar.badge.plus")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedDateRange.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "平均完了率",
                value: viewModel.formatPercentage(viewModel.weeklyCompletionRate),
                icon: "checkmark.circle.fill",
                color: .green
            )

            summaryCard(
                title: "AI採用率",
                value: viewModel.formatPercentage(viewModel.weeklyAIAcceptanceRate),
                icon: "brain.head.profile",
                color: AsaColors.coffeeBrown
            )

            summaryCard(
                title: "朝活スコア",
                value: viewModel.formatPercentage(viewModel.weeklyEarlyMorningScore),
                icon: "sunrise.fill",
                color: AsaColors.mocha
            )
        }
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

            if !viewModel.weeklyTrendData.isEmpty {
                Chart {
                    ForEach(viewModel.weeklyTrendData) { data in
                        // 完了率
                        LineMark(
                            x: .value("日付", data.dateLabel),
                            y: .value("完了率", data.completionRate * 100)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())

                        // AI採用率
                        LineMark(
                            x: .value("日付", data.dateLabel),
                            y: .value("AI採用率", data.aiAcceptanceRate * 100)
                        )
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())

                        // 朝活スコア
                        LineMark(
                            x: .value("日付", data.dateLabel),
                            y: .value("朝活スコア", data.earlyMorningScore * 100)
                        )
                        .foregroundStyle(AsaColors.mocha)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())
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
                        legendItem(color: .green, label: "完了率")
                        legendItem(color: AsaColors.coffeeBrown, label: "AI採用率")
                        legendItem(color: AsaColors.mocha, label: "朝活スコア")
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

    // MARK: - Daily Table

    private var dailyTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title2)
                    .foregroundColor(AsaColors.darkSlate)

                Text("日別詳細")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            VStack(spacing: 1) {
                // ヘッダー
                HStack(spacing: 12) {
                    Text("日付")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    Text("完了率")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("AI採用")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("朝活")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                .background(AsaColors.darkSlate.opacity(0.1))

                // データ行
                ForEach(viewModel.weeklyAnalytics, id: \.id) { analytics in
                    dailyRow(analytics: analytics)
                        .background(
                            selectedDate == analytics.date
                                ? AsaColors.coffeeBrown.opacity(0.1)
                                : Color.clear
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = selectedDate == analytics.date ? nil : analytics.date
                            }
                        }
                }
            }
            .background(AsaColors.softCream.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Helper Views

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func dailyRow(analytics: TaskAnalytics) -> some View {
        HStack(spacing: 12) {
            Text(formatDate(analytics.date))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(viewModel.formatPercentage(analytics.completionRate))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(metricColor(analytics.completionRate))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(viewModel.formatPercentage(analytics.aiAcceptanceRate))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(metricColor(analytics.aiAcceptanceRate))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(viewModel.formatPercentage(analytics.earlyMorningProductivityScore))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(metricColor(analytics.earlyMorningProductivityScore))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
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

    // MARK: - Helper Functions

    private var periodText: String {
        guard let firstDate = viewModel.weeklyAnalytics.first?.date,
              let lastDate = viewModel.weeklyAnalytics.last?.date else {
            return "データなし"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")

        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func metricColor(_ value: Double) -> Color {
        switch value {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return AsaColors.coffeeBrown
        case 0.4..<0.6:
            return .orange
        case 0.01..<0.4:
            return .red
        default:
            return .secondary
        }
    }
}
