//
//  SleepTab.swift
//  AsaHealthDashboard
//
//  睡眠タブ
//

import SwiftUI
import Charts
import AsaUIKit

struct SleepTab: View {
    let viewModel: HealthDashboardViewModel
    @State private var selectedPeriod: TimePeriod = .week

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

                        // 今日の睡眠サマリー
                        if let metric = viewModel.todayMetric(for: .sleep) {
                            SleepSummaryCard(metric: metric)
                        } else {
                            SleepEmptyCard()
                        }

                        // 睡眠時間チャート
                        SleepDurationChart(
                            metrics: viewModel.metrics(for: .sleep),
                            period: selectedPeriod
                        )

                        // 睡眠統計
                        SleepStatisticsCard(metrics: viewModel.metrics(for: .sleep))
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("睡眠")
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

// MARK: - 睡眠サマリーカード

struct SleepSummaryCard: View {
    let metric: HealthMetric

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    Text("今日の睡眠")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    if metric.isGoalAchieved {
                        Label("目標達成", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                HStack(spacing: 24) {
                    // 睡眠時間リング
                    ZStack {
                        Circle()
                            .stroke(HealthCategory.sleep.color.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: min(metric.progress, 1.0))
                            .stroke(
                                HealthCategory.sleep.color,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: metric.progress)

                        VStack(spacing: 2) {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(HealthCategory.sleep.color)
                            Text(metric.formattedValue)
                                .font(.headline)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SleepInfoRow(
                            icon: "bed.double.fill",
                            title: "睡眠時間",
                            value: metric.formattedValue
                        )

                        if let goal = metric.formattedGoal {
                            SleepInfoRow(
                                icon: "target",
                                title: "目標",
                                value: "\(goal)時間"
                            )
                        }

                        SleepInfoRow(
                            icon: "percent",
                            title: "達成率",
                            value: "\(metric.progressPercentage)%"
                        )
                    }

                    Spacer()
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct SleepInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(HealthCategory.sleep.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(AsaColors.darkSlate)
            }
        }
    }
}

// MARK: - 睡眠データなしカード

struct SleepEmptyCard: View {
    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 48))
                    .foregroundColor(HealthCategory.sleep.color.opacity(0.5))

                Text("睡眠データがありません")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Text("Apple Watchを装着して睡眠すると、\n自動的に睡眠データが記録されます")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
}

// MARK: - 睡眠時間チャート

struct SleepDurationChart: View {
    let metrics: [HealthMetric]
    let period: TimePeriod

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("睡眠時間の推移")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    if !metrics.isEmpty {
                        Text("平均: \(String(format: "%.1f", metrics.average))時間")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                if metrics.isEmpty {
                    EmptyStateView(
                        icon: "moon.zzz",
                        title: "データがありません",
                        message: "この期間の睡眠データはまだ記録されていません"
                    )
                    .frame(height: 200)
                } else {
                    Chart(metrics) { metric in
                        BarMark(
                            x: .value("日付", metric.date, unit: .day),
                            y: .value("睡眠時間", metric.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [HealthCategory.sleep.color, HealthCategory.sleep.color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)

                        // 目標ライン
                        if let goal = metric.goal {
                            RuleMark(y: .value("目標", goal))
                                .foregroundStyle(.green.opacity(0.7))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("目標")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                        }
                    }
                    .chartYAxisLabel("時間")
                    .chartYScale(domain: 0...12)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
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

// MARK: - 睡眠統計カード

struct SleepStatisticsCard: View {
    let metrics: [HealthMetric]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠統計")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if metrics.isEmpty {
                    Text("データがありません")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SleepStatItem(
                            icon: "chart.bar.fill",
                            title: "平均睡眠時間",
                            value: String(format: "%.1f", metrics.average),
                            unit: "時間"
                        )

                        SleepStatItem(
                            icon: "arrow.up.circle.fill",
                            title: "最長睡眠",
                            value: String(format: "%.1f", metrics.maxValue),
                            unit: "時間"
                        )

                        SleepStatItem(
                            icon: "arrow.down.circle.fill",
                            title: "最短睡眠",
                            value: String(format: "%.1f", metrics.minValue),
                            unit: "時間"
                        )

                        SleepStatItem(
                            icon: "checkmark.circle.fill",
                            title: "目標達成日",
                            value: "\(metrics.filter { $0.isGoalAchieved }.count)",
                            unit: "日"
                        )
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct SleepStatItem: View {
    let icon: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(HealthCategory.sleep.color)

            VStack(alignment: .leading, spacing: 2) {
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
}

#Preview {
    SleepTab(viewModel: HealthDashboardViewModel())
}
