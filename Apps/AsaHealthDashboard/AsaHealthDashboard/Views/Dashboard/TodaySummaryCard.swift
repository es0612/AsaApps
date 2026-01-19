//
//  TodaySummaryCard.swift
//  AsaHealthDashboard
//
//  今日のサマリーカード
//

import SwiftUI
import AsaUIKit

struct TodaySummaryCard: View {
    let metrics: [HealthMetric]

    private var achievedCount: Int {
        metrics.filter { $0.isGoalAchieved }.count
    }

    private var totalCount: Int {
        metrics.count
    }

    private var overallProgress: Double {
        guard totalCount > 0 else { return 0 }
        return metrics.map { $0.progress }.reduce(0, +) / Double(totalCount)
    }

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日の進捗")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)

                        Text("\(achievedCount) / \(totalCount) 達成")
                            .font(.title2.bold())
                            .foregroundColor(AsaColors.coffeeBrown)
                    }

                    Spacer()

                    // 総合プログレスリング
                    ZStack {
                        Circle()
                            .stroke(AsaColors.softCream, lineWidth: 10)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: overallProgress)
                            .stroke(AsaColors.coffeeBrown, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: overallProgress)

                        Text("\(Int(overallProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }

                Divider()

                // 各カテゴリのミニプログレス
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(HealthCategory.allCases) { category in
                        if let metric = metrics.first(where: { $0.category == category }) {
                            MiniMetricView(metric: metric)
                        }
                    }
                }

                // 励ましメッセージ
                if achievedCount == totalCount && totalCount > 0 {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("素晴らしい！全ての目標を達成しました！")
                            .font(.caption)
                            .foregroundColor(AsaColors.mocha)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(AsaColors.softCream.opacity(0.5))
                    .cornerRadius(8)
                } else if overallProgress > 0.5 {
                    Text("順調です！あと少しで目標達成です")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding()
        }
    }
}

// MARK: - ミニメトリックビュー

struct MiniMetricView: View {
    let metric: HealthMetric

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(metric.category.color.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: metric.progress)
                    .stroke(metric.category.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Image(systemName: metric.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(metric.category.color)
            }

            Text(metric.category.displayName)
                .font(.system(size: 9))
                .foregroundColor(AsaColors.mutedSage)
                .lineLimit(1)
        }
    }
}

#Preview {
    let sampleMetrics = HealthCategory.allCases.map { category in
        HealthMetric(
            category: category,
            date: Date(),
            value: Double.random(in: 0...category.defaultGoal * 1.2),
            goal: category.defaultGoal
        )
    }

    return TodaySummaryCard(metrics: sampleMetrics)
        .padding()
}
