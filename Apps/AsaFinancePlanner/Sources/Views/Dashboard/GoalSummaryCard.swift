import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct GoalSummaryCard: View {
    let goal: FinancialGoal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.category.iconName)
                .font(.title3)
                .foregroundStyle(Color(hex: goal.category.colorHex))
                .frame(width: 40, height: 40)
                .background(Color(hex: goal.category.colorHex).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AsaColors.darkSlate)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatCurrency(goal.currentAmount))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AsaColors.coffeeBrown)

                    Text("/")
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)

                    Text(formatCurrency(goal.targetAmount))
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }
            }

            Spacer()

            circularProgress
        }
        .padding(12)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name)、進捗\(String(format: "%.0f", goal.progressPercentage * 100))パーセント")
    }

    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(AsaColors.mutedSage.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(goal.progressPercentage, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(String(format: "%.0f%%", goal.progressPercentage * 100))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(AsaColors.darkSlate)
        }
        .frame(width: 44, height: 44)
    }

    private var progressColor: Color {
        let progress = goal.progressPercentage
        if progress >= 1.0 { return .green }
        if progress >= 0.75 { return AsaColors.coffeeBrown }
        if progress >= 0.5 { return .orange }
        return .red.opacity(0.7)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }
}
