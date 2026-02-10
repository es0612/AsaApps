import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct GoalDetailView: View {
    @State var viewModel: GoalViewModel
    let goal: FinancialGoal
    @State private var showEditSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                progressSection
                feasibilitySection
                detailSection
            }
            .padding()
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.prepareForEditing(goal)
                        showEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                        dismiss()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AsaColors.coffeeBrown)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            GoalFormSheet(viewModel: viewModel, isEditing: true)
        }
        .onAppear { viewModel.analyzeFeasibility(for: goal) }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: goal.category.iconName)
                .font(.title)
                .foregroundStyle(Color(hex: goal.category.colorHex))
                .frame(width: 56, height: 56)
                .background(Color(hex: goal.category.colorHex).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.category.displayName)
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                Text(goal.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)
            }
            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("進捗状況")
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)
                Spacer()
                Text(String(format: "%.1f%%", goal.progressPercentage * 100))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            ProgressView(value: min(goal.progressPercentage, 1.0))
                .tint(AsaColors.coffeeBrown)
                .scaleEffect(y: 2)

            HStack {
                VStack(alignment: .leading) {
                    Text("現在")
                        .font(.caption2)
                        .foregroundStyle(AsaColors.mutedSage)
                    Text(formatCurrency(goal.currentAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("目標")
                        .font(.caption2)
                        .foregroundStyle(AsaColors.mutedSage)
                    Text(formatCurrency(goal.targetAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(16)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var feasibilitySection: some View {
        Group {
            if let result = viewModel.feasibilityResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text("達成可能性分析")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)

                    HStack {
                        statusBadge(isFeasible: result.isFeasible)
                        Spacer()
                        Text(String(format: "成功確率: %.0f%%", result.probabilityOfSuccess * 100))
                            .font(.subheadline)
                            .foregroundStyle(AsaColors.darkSlate)
                    }

                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)

                    if !result.isFeasible {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("不足額")
                                    .font(.caption)
                                    .foregroundStyle(AsaColors.mutedSage)
                                Spacer()
                                Text(formatCurrency(result.shortfall))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.red)
                            }
                            HStack {
                                Text("必要月額追加")
                                    .font(.caption)
                                    .foregroundStyle(AsaColors.mutedSage)
                                Spacer()
                                Text(formatCurrency(result.requiredMonthlyContribution))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AsaColors.coffeeBrown)
                            }
                        }
                    }
                }
                .padding(16)
                .background(AsaColors.softCream.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            detailRow(label: "残り必要額", value: formatCurrency(goal.remainingAmount))
            detailRow(label: "目標期日", value: formatDate(goal.targetDate))
            detailRow(label: "残り月数", value: "\(goal.remainingMonths)ヶ月")
            detailRow(label: "月額必要額", value: formatCurrency(goal.requiredMonthlyContribution))

            if !goal.note.isEmpty {
                detailRow(label: "メモ", value: goal.note)
            }
        }
        .padding(16)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }

    private func statusBadge(isFeasible: Bool) -> some View {
        Text(isFeasible ? "達成可能" : "要見直し")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isFeasible ? .green : .orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isFeasible ? .green.opacity(0.1) : .orange.opacity(0.1))
            .clipShape(Capsule())
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
