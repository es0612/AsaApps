import SwiftUI
import AsaLifeLogKit

// MARK: - GoalSettings

/// 目標設定ビュー
struct GoalSettings: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("朝活時間帯") {
                Stepper(
                    "開始時間: \(viewModel.preferences?.morningRoutineStartHour ?? 5)時",
                    value: Binding(
                        get: { viewModel.preferences?.morningRoutineStartHour ?? 5 },
                        set: { viewModel.preferences?.morningRoutineStartHour = $0 }
                    ),
                    in: 3...8
                )

                Stepper(
                    "終了時間: \(viewModel.preferences?.morningRoutineEndHour ?? 7)時",
                    value: Binding(
                        get: { viewModel.preferences?.morningRoutineEndHour ?? 7 },
                        set: { viewModel.preferences?.morningRoutineEndHour = $0 }
                    ),
                    in: 5...10
                )
            }

            Section("チャート表示期間") {
                Picker("デフォルト期間", selection: Binding(
                    get: { viewModel.preferences?.preferredChartPeriod ?? .week },
                    set: { viewModel.preferences?.preferredChartPeriod = $0 }
                )) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
            }
        }
        .navigationTitle("目標設定")
        .onDisappear {
            Task { await viewModel.savePreferences() }
        }
    }
}
