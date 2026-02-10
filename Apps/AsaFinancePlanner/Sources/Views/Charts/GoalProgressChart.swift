import SwiftUI
import Charts
import AsaUIKit
import AsaFinancePlannerKit

struct GoalProgressChart: View {
    let goals: [FinancialGoal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目標進捗")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if goals.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
    }

    private var chartContent: some View {
        Chart(goals, id: \.id) { goal in
            BarMark(
                x: .value("進捗", min(goal.progressPercentage, 1.0)),
                y: .value("目標", goal.name)
            )
            .foregroundStyle(progressColor(for: goal.progressPercentage))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .annotation(position: .trailing) {
                Text(String(format: "%.0f%%", goal.progressPercentage * 100))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AsaColors.darkSlate)
            }
        }
        .chartXScale(domain: 0...1.0)
        .chartXAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text(String(format: "%.0f%%", pct * 100))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: CGFloat(goals.count) * 50 + 20)
        .accessibilityLabel("目標進捗チャート、\(goals.count)件の目標")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.largeTitle)
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
            Text("目標がありません")
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private func progressColor(for progress: Double) -> Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.75 { return AsaColors.coffeeBrown }
        if progress >= 0.5 { return .orange }
        return .red.opacity(0.7)
    }
}
