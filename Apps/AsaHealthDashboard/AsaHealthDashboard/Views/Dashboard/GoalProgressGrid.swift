//
//  GoalProgressGrid.swift
//  AsaHealthDashboard
//
//  目標達成グリッド
//

import SwiftUI
import AsaUIKit

struct GoalProgressGrid: View {
    let metrics: [HealthMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目標達成状況")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    GoalProgressCard(metric: metric)
                }
            }
        }
    }
}

// MARK: - 目標進捗カード

struct GoalProgressCard: View {
    let metric: HealthMetric

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    Image(systemName: metric.category.icon)
                        .font(.title2)
                        .foregroundColor(metric.category.color)
                        .frame(width: 36, height: 36)
                        .background(metric.category.color.opacity(0.1))
                        .cornerRadius(8)

                    Spacer()

                    if metric.isGoalAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                // カテゴリ名
                Text(metric.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)

                // 値
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(metric.shortFormattedValue)
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.darkSlate)

                    Text(metric.category.unit)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AsaColors.softCream)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(metric.category.color)
                            .frame(width: geometry.size.width * min(metric.progress, 1.0), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: metric.progress)
                    }
                }
                .frame(height: 8)

                // 目標との比較
                if let goal = metric.formattedGoal {
                    Text("目標: \(goal)\(metric.category.unit)")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding()
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

    return GoalProgressGrid(metrics: sampleMetrics)
        .padding()
}
