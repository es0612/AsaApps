import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct ScenarioComparisonView: View {
    let scenarios: [ScenarioProjection]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("シナリオ比較詳細")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if scenarios.isEmpty {
                Text("比較するシナリオがありません")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(scenarios) { scenario in
                    scenarioSummary(scenario)
                }
            }
        }
    }

    private func scenarioSummary(_ scenario: ScenarioProjection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scenario.scenarioName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AsaColors.darkSlate)

            if let lastPoint = scenario.points.last {
                HStack {
                    VStack(alignment: .leading) {
                        Text("最終名目値")
                            .font(.caption2)
                            .foregroundStyle(AsaColors.mutedSage)
                        Text(formatCurrency(lastPoint.nominalValue))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("最終実質値")
                            .font(.caption2)
                            .foregroundStyle(AsaColors.mutedSage)
                        Text(formatCurrency(lastPoint.realValue))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(12)
        .background(AsaColors.softCream.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }
}
