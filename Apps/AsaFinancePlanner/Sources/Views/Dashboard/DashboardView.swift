import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct DashboardView: View {
    @State var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    assetSummarySection
                    goalProgressSection
                    insightsSection
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .onAppear { viewModel.loadDashboard() }
            .refreshable { viewModel.loadDashboard() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Asset Summary

    private var assetSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("総資産額")
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                    Text(formatCurrency(viewModel.totalAssetValue))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AsaColors.darkSlate)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            Divider()

            HStack {
                statItem(
                    title: "月額積立",
                    value: formatCurrency(viewModel.monthlyContribution),
                    icon: "arrow.up.circle.fill"
                )
                Spacer()
                statItem(
                    title: "目標達成率",
                    value: String(format: "%.0f%%", viewModel.goalProgressSummary * 100),
                    icon: "target"
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AsaColors.softCream.opacity(0.4), AsaColors.softCream.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AsaColors.coffeeBrown)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AsaColors.mutedSage)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.darkSlate)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(value)")
    }

    // MARK: - Goal Progress

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目標進捗")
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)
                Spacer()
            }

            if viewModel.topGoals.isEmpty {
                Text("目標を設定してください")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.topGoals, id: \.id) { goal in
                    GoalSummaryCard(goal: goal)
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.insights.isEmpty {
                Text("インサイト")
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)

                ForEach(viewModel.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }
}
