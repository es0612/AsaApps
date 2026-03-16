//
//  AddAlarmView.swift
//  AsaSmartAlarm
//
//  アラーム追加画面
//

import SwiftUI
import AsaUIKit

// MARK: - アラーム追加ビュー

/// 新しいアラームを追加する画面
struct AddAlarmView: View {
    // MARK: - Properties

    let viewModel: AlarmViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
    }()
    @State private var label: String = ""
    @State private var repeatDays: [Int] = []
    @State private var weatherAdjustmentEnabled: Bool = true
    @State private var eventAdjustmentEnabled: Bool = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 時刻選択
                Section {
                    DatePicker(
                        "時刻",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                // ラベル
                Section("ラベル") {
                    TextField("アラームの名前", text: $label)
                }

                // 繰り返し
                Section("繰り返し") {
                    VStack(alignment: .leading, spacing: 16) {
                        WeekdayPickerView(selectedDays: $repeatDays)

                        WeekdayPresetButtons(selectedDays: $repeatDays)
                    }
                    .padding(.vertical, 8)
                }

                // スマート機能
                Section {
                    Toggle(isOn: $weatherAdjustmentEnabled) {
                        Label("天気による調整", systemImage: "cloud.sun.fill")
                    }
                    .tint(AsaColors.coffeeBrown)

                    if weatherAdjustmentEnabled {
                        Text("雨や雪の場合、自動的に早めに起こします")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle(isOn: $eventAdjustmentEnabled) {
                        Label("予定による調整", systemImage: "calendar")
                    }
                    .tint(AsaColors.coffeeBrown)

                    if eventAdjustmentEnabled {
                        Text("朝の予定に合わせて、準備時間を考慮した時刻に起こします")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("スマート機能")
                } footer: {
                    Text("スマート機能を有効にすると、天気や予定に応じてアラーム時刻が自動調整されます")
                }
            }
            .navigationTitle("アラームを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveAlarm()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func saveAlarm() {
        Task {
            await viewModel.addAlarm(
                baseTime: selectedTime,
                label: label,
                repeatDays: repeatDays,
                weatherAdjustmentEnabled: weatherAdjustmentEnabled,
                eventAdjustmentEnabled: eventAdjustmentEnabled
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("アラーム追加") {
    AddAlarmView(viewModel: .preview)
}
