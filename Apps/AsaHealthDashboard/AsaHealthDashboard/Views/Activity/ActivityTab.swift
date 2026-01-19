//
//  ActivityTab.swift
//  AsaHealthDashboard
//
//  アクティビティタブ
//

import SwiftUI
import Charts
import AsaUIKit

struct ActivityTab: View {
    let viewModel: HealthDashboardViewModel
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedCategory: HealthCategory = .steps

    // アクティビティカテゴリのみ
    private let activityCategories: [HealthCategory] = [.steps, .distance, .calories, .exerciseTime]

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.1)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 期間セレクター
                        SegmentedPeriodSelector(selectedPeriod: $selectedPeriod)
                            .padding(.horizontal)

                        // カテゴリセレクター
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(activityCategories) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // 選択されたカテゴリのチャート
                        ActivityChartCard(
                            metrics: viewModel.metrics(for: selectedCategory),
                            category: selectedCategory,
                            period: selectedPeriod
                        )

                        // 今日のサマリー
                        if let metric = viewModel.todayMetric(for: selectedCategory) {
                            TodayActivityCard(metric: metric)
                        }

                        // 統計サマリー
                        StatisticsSummaryCard(
                            metrics: viewModel.metrics(for: selectedCategory),
                            category: selectedCategory
                        )
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("アクティビティ")
            .onChange(of: selectedPeriod) { _, newPeriod in
                Task {
                    await viewModel.changePeriod(to: newPeriod)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadPeriodData()
                }
            }
        }
    }
}

// MARK: - カテゴリチップ

struct CategoryChip: View {
    let category: HealthCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : category.color.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - アクティビティチャートカード

struct ActivityChartCard: View {
    let metrics: [HealthMetric]
    let category: HealthCategory
    let period: TimePeriod

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(category.displayName)の推移")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    if !metrics.isEmpty {
                        Text("平均: \(String(format: "%.0f", metrics.average))\(category.unit)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                if metrics.isEmpty {
                    EmptyStateView(
                        icon: category.icon,
                        title: "データがありません",
                        message: "この期間のデータはまだ記録されていません"
                    )
                    .frame(height: 200)
                } else {
                    Chart(metrics) { metric in
                        BarMark(
                            x: .value("日付", metric.date, unit: .day),
                            y: .value(category.displayName, metric.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)

                        // 目標ライン
                        if let goal = metric.goal {
                            RuleMark(y: .value("目標", goal))
                                .foregroundStyle(AsaColors.mutedSage)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }
                    }
                    .chartYAxisLabel(category.unit)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: period == .day ? .hour : .day)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: period == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month().day())
                        }
                    }
                    .frame(height: 200)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: - 今日のアクティビティカード

struct TodayActivityCard: View {
    let metric: HealthMetric

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                MetricProgressRing(metric: metric, size: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text("今日の\(metric.category.displayName)")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(metric.formattedValue)
                            .font(.title2.bold())
                            .foregroundColor(AsaColors.darkSlate)

                        Text(metric.category.unit)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    if let goal = metric.formattedGoal {
                        Text("目標: \(goal)\(metric.category.unit)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()

                if metric.isGoalAchieved {
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("達成！")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: - 統計サマリーカード

struct StatisticsSummaryCard: View {
    let metrics: [HealthMetric]
    let category: HealthCategory

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("統計")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if metrics.isEmpty {
                    Text("データがありません")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatItem(
                            title: "合計",
                            value: String(format: "%.0f", metrics.total),
                            unit: category.unit
                        )

                        StatItem(
                            title: "平均",
                            value: String(format: "%.0f", metrics.average),
                            unit: category.unit
                        )

                        StatItem(
                            title: "最大",
                            value: String(format: "%.0f", metrics.maxValue),
                            unit: category.unit
                        )

                        StatItem(
                            title: "最小",
                            value: String(format: "%.0f", metrics.minValue),
                            unit: category.unit
                        )
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }
}

#Preview {
    ActivityTab(viewModel: HealthDashboardViewModel())
}
