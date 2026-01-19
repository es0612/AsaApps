//
//  MetricCard.swift
//  AsaHealthDashboard
//
//  メトリックカード
//

import SwiftUI
import AsaUIKit

struct MetricCard: View {
    let metric: HealthMetric
    let showGoal: Bool

    init(metric: HealthMetric, showGoal: Bool = true) {
        self.metric = metric
        self.showGoal = showGoal
    }

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: metric.category.icon)
                    .font(.title2)
                    .foregroundColor(metric.category.color)
                    .frame(width: 44, height: 44)
                    .background(metric.category.color.opacity(0.1))
                    .cornerRadius(10)

                // 情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(metric.formattedValue)
                            .font(.title3.bold())
                            .foregroundColor(AsaColors.darkSlate)

                        Text(metric.category.unit)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()

                // プログレスまたは達成マーク
                if showGoal {
                    VStack(alignment: .trailing, spacing: 4) {
                        if metric.isGoalAchieved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        } else {
                            Text("\(metric.progressPercentage)%")
                                .font(.headline)
                                .foregroundColor(metric.category.color)
                        }

                        if let goal = metric.formattedGoal {
                            Text("/ \(goal)")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - コンパクトメトリックカード

struct CompactMetricCard: View {
    let metric: HealthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.category.icon)
                    .foregroundColor(metric.category.color)
                    .font(.caption)

                Text(metric.category.displayName)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Text(metric.shortFormattedValue)
                .font(.title3.bold())
                .foregroundColor(AsaColors.darkSlate)

            Text(metric.category.unit)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCard(
            metric: HealthMetric(
                category: .steps,
                date: Date(),
                value: 8500,
                goal: 10000
            )
        )

        MetricCard(
            metric: HealthMetric(
                category: .calories,
                date: Date(),
                value: 550,
                goal: 500
            )
        )

        HStack {
            CompactMetricCard(
                metric: HealthMetric(
                    category: .distance,
                    date: Date(),
                    value: 5.2,
                    goal: 8.0
                )
            )

            CompactMetricCard(
                metric: HealthMetric(
                    category: .exerciseTime,
                    date: Date(),
                    value: 25,
                    goal: 30
                )
            )
        }
    }
    .padding()
}
