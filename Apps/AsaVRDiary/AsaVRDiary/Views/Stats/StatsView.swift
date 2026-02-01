//
//  StatsView.swift
//  AsaVRDiary
//
//  統計画面
//

import SwiftUI
import Charts

/// 統計画面
struct StatsView: View {
    @Bindable var viewModel: StatsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // サマリーカード
                    summaryCards

                    // 週間チャート
                    weeklyChart

                    // カテゴリ分布
                    categoryDistribution

                    // 気分分布
                    moodDistribution
                }
                .padding()
            }
            .navigationTitle("統計")
            .onAppear {
                viewModel.loadStats()
            }
            .refreshable {
                viewModel.loadStats()
            }
        }
    }

    // MARK: - Subviews

    /// サマリーカード
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // 総日記数
            StatCard(
                title: "総日記数",
                value: "\(viewModel.stats.totalEntries)",
                icon: "book.fill",
                color: .blue
            )

            // 今月の日記数
            StatCard(
                title: "今月",
                value: "\(viewModel.stats.thisMonthEntries)",
                icon: "calendar",
                color: .green
            )

            // 連続記録
            StatCard(
                title: "連続記録",
                value: "\(viewModel.stats.streakDays)日",
                icon: viewModel.streakStatus().icon,
                color: .orange,
                subtitle: viewModel.streakStatus().message
            )

            // 平均気分強度
            StatCard(
                title: "平均強度",
                value: String(format: "%.1f", viewModel.stats.averageMoodIntensity),
                icon: "heart.fill",
                color: .pink
            )
        }
    }

    /// 週間チャート
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間の記録")
                .font(.headline)

            if viewModel.stats.weeklyEntries.isEmpty {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(viewModel.stats.weeklyEntries) { entry in
                    BarMark(
                        x: .value("週", entry.formattedWeek),
                        y: .value("日記数", entry.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// カテゴリ分布
    private var categoryDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ分布")
                .font(.headline)

            let percentages = viewModel.categoryPercentages()
            if percentages.isEmpty {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(percentages.prefix(5), id: \.0) { category, percentage in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                                .frame(width: 24)

                            Text(category.displayName)
                                .font(.subheadline)

                            Spacer()

                            Text(String(format: "%.1f%%", percentage))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.color.opacity(0.3))
                                .frame(width: geometry.size.width)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(category.color)
                                        .frame(width: geometry.size.width * percentage / 100)
                                }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// 気分分布
    private var moodDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("気分分布")
                .font(.headline)

            let percentages = viewModel.moodPercentages()
            if percentages.isEmpty {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // トップ気分
                if let topMood = viewModel.stats.topMood {
                    HStack {
                        Text("最も多い気分:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(topMood.emoji)
                            .font(.title2)
                        Text(topMood.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 8)
                }

                // 気分グリッド
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(percentages.prefix(10), id: \.0) { mood, percentage in
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)

                            Text(String(format: "%.0f%%", percentage))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(mood.color.opacity(percentage / 100 * 0.5 + 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// 統計カード
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    StatsView(viewModel: StatsViewModel())
}
