//
//  MetricProgressRing.swift
//  AsaHealthDashboard
//
//  円形プログレスコンポーネント
//

import SwiftUI
import AsaUIKit

struct MetricProgressRing: View {
    let metric: HealthMetric
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(lineWidth: size * 0.1)
                .opacity(0.2)
                .foregroundColor(metric.category.color)

            // プログレスリング
            Circle()
                .trim(from: 0.0, to: CGFloat(min(metric.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .foregroundColor(metric.category.color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.spring(), value: metric.progress)

            // 中央のコンテンツ
            VStack(spacing: size * 0.03) {
                Image(systemName: metric.category.icon)
                    .font(.system(size: size * 0.2))
                    .foregroundColor(metric.category.color)

                Text(metric.shortFormattedValue)
                    .font(.system(size: size * 0.15, weight: .bold))
                    .foregroundColor(AsaColors.darkSlate)

                Text(metric.category.unit)
                    .font(.system(size: size * 0.08))
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 大きいサイズのプログレスリング

struct LargeMetricProgressRing: View {
    let metric: HealthMetric

    var body: some View {
        VStack(spacing: 12) {
            MetricProgressRing(metric: metric, size: 120)

            VStack(spacing: 4) {
                Text(metric.category.displayName)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if let goal = metric.formattedGoal {
                    Text("目標: \(goal)\(metric.category.unit)")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Text("\(metric.progressPercentage)%達成")
                    .font(.caption.bold())
                    .foregroundColor(metric.isGoalAchieved ? .green : metric.category.color)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MetricProgressRing(
            metric: HealthMetric(
                category: .steps,
                date: Date(),
                value: 7500,
                goal: 10000
            ),
            size: 100
        )

        LargeMetricProgressRing(
            metric: HealthMetric(
                category: .calories,
                date: Date(),
                value: 450,
                goal: 500
            )
        )
    }
    .padding()
}
