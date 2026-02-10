import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct RebalanceSheet: View {
    let suggestions: [RebalanceSuggestion]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("目標配分との乖離が5%以上の資産クラスについて、リバランス提案を表示しています。")
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }

                Section("リバランス提案") {
                    ForEach(suggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                }
            }
            .navigationTitle("リバランス提案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AsaColors.coffeeBrown)
                }
            }
        }
    }

    private func suggestionRow(_ suggestion: RebalanceSuggestion) -> some View {
        HStack {
            Image(systemName: suggestion.assetClass.iconName)
                .foregroundStyle(Color(hex: suggestion.assetClass.colorHex))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.assetClass.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(String(format: "%.1f%%", suggestion.currentPercentage * 100))
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(AsaColors.mutedSage)
                    Text(String(format: "%.1f%%", suggestion.targetPercentage * 100))
                        .font(.caption)
                        .foregroundStyle(AsaColors.coffeeBrown)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                actionBadge(suggestion.action)
                Text(formatCurrency(suggestion.adjustmentAmount))
                    .font(.caption)
                    .foregroundStyle(AsaColors.darkSlate)
            }
        }
        .padding(.vertical, 4)
    }

    private func actionBadge(_ action: RebalanceAction) -> some View {
        Text(action.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(actionColor(action))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(actionColor(action).opacity(0.1))
            .clipShape(Capsule())
    }

    private func actionColor(_ action: RebalanceAction) -> Color {
        switch action {
        case .buy: return .green
        case .sell: return .red
        case .hold: return AsaColors.mutedSage
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }
}
