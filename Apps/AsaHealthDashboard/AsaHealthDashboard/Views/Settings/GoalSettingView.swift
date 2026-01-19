//
//  GoalSettingView.swift
//  AsaHealthDashboard
//
//  目標設定画面
//

import SwiftUI
import AsaUIKit

struct GoalSettingView: View {
    let viewModel: HealthDashboardViewModel
    @State private var goalSettingsVM: GoalSettingsViewModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AsaColors.softCream.opacity(0.1)
                .ignoresSafeArea()

            if let settingsVM = goalSettingsVM {
                List {
                    ForEach(HealthCategory.allCases) { category in
                        GoalSettingRow(
                            category: category,
                            value: Binding(
                                get: { settingsVM.goalValue(for: category) },
                                set: { settingsVM.updateGoal(for: category, value: $0) }
                            )
                        )
                    }

                    Section {
                        Button {
                            settingsVM.resetToDefaults()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("デフォルトに戻す")
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                LoadingView()
            }
        }
        .navigationTitle("目標設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    goalSettingsVM?.saveAllGoals()
                    dismiss()
                }
                .disabled(goalSettingsVM?.hasUnsavedChanges != true)
            }
        }
        .onAppear {
            goalSettingsVM = GoalSettingsViewModel(dashboardViewModel: viewModel)
        }
    }
}

// MARK: - 目標設定行

struct GoalSettingRow: View {
    let category: HealthCategory
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)

                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("\(formattedValue)\(category.unit)")
                    .font(.subheadline.bold())
                    .foregroundColor(category.color)
            }

            Slider(
                value: $value,
                in: category.goalRange,
                step: category.goalStep
            )
            .tint(category.color)

            HStack {
                Text("最小: \(formatValue(category.goalRange.lowerBound))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                Spacer()

                Text("デフォルト: \(formatValue(category.defaultGoal))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                Spacer()

                Text("最大: \(formatValue(category.goalRange.upperBound))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .padding(.vertical, 8)
    }

    private var formattedValue: String {
        formatValue(value)
    }

    private func formatValue(_ val: Double) -> String {
        switch category {
        case .steps:
            return String(format: "%.0f", val)
        case .distance, .sleep:
            return String(format: "%.1f", val)
        case .calories, .exerciseTime:
            return String(format: "%.0f", val)
        }
    }
}

#Preview {
    NavigationStack {
        GoalSettingView(viewModel: HealthDashboardViewModel())
    }
}
