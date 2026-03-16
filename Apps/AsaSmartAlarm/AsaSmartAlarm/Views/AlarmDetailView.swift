//
//  AlarmDetailView.swift
//  AsaSmartAlarm
//
//  アラーム詳細・編集画面
//

import SwiftUI
import AsaUIKit

// MARK: - アラーム詳細ビュー

/// アラームの詳細を表示・編集する画面
struct AlarmDetailView: View {
    // MARK: - Properties

    let alarm: SmartAlarm
    let calculation: AlarmCalculationResult?
    let onSave: (SmartAlarm) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date
    @State private var label: String
    @State private var repeatDays: [Int]
    @State private var weatherAdjustmentEnabled: Bool
    @State private var eventAdjustmentEnabled: Bool
    @State private var showingDeleteConfirmation: Bool = false

    // MARK: - Initializer

    init(
        alarm: SmartAlarm,
        calculation: AlarmCalculationResult?,
        onSave: @escaping (SmartAlarm) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.alarm = alarm
        self.calculation = calculation
        self.onSave = onSave
        self.onDelete = onDelete

        _selectedTime = State(initialValue: alarm.baseTime)
        _label = State(initialValue: alarm.label)
        _repeatDays = State(initialValue: alarm.repeatDays)
        _weatherAdjustmentEnabled = State(initialValue: alarm.weatherAdjustmentEnabled)
        _eventAdjustmentEnabled = State(initialValue: alarm.eventAdjustmentEnabled)
    }

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

                // 次回のアラーム情報
                if let calc = calculation, alarm.isEnabled {
                    Section("次回のアラーム") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("予定時刻")
                                Spacer()
                                Text(formatDateTime(calc.adjustedTime))
                                    .foregroundStyle(.secondary)
                            }

                            if calc.hasAdjustments {
                                HStack {
                                    Text("調整")
                                    Spacer()
                                    Text(calc.timeChangeDescription)
                                        .foregroundStyle(.orange)
                                }

                                Divider()

                                AdjustmentRuleSummary(calculation: calc)
                            }
                        }
                    }
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
                Section("スマート機能") {
                    Toggle(isOn: $weatherAdjustmentEnabled) {
                        Label("天気による調整", systemImage: "cloud.sun.fill")
                    }
                    .tint(AsaColors.coffeeBrown)

                    Toggle(isOn: $eventAdjustmentEnabled) {
                        Label("予定による調整", systemImage: "calendar")
                    }
                    .tint(AsaColors.coffeeBrown)
                }

                // 天気ルール設定
                if weatherAdjustmentEnabled {
                    Section("天気ルール") {
                        ForEach(alarm.adjustmentRules.filter { $0.conditionType == .weather }) { rule in
                            WeatherRuleRow(rule: rule)
                        }
                    }
                }

                // 削除
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("アラームを削除")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("アラームを編集")
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
            .confirmationDialog(
                "このアラームを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    // MARK: - Private Methods

    private func saveAlarm() {
        alarm.update(
            baseTime: selectedTime,
            label: label,
            repeatDays: repeatDays,
            weatherAdjustmentEnabled: weatherAdjustmentEnabled,
            eventAdjustmentEnabled: eventAdjustmentEnabled
        )
        onSave(alarm)
        dismiss()
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (EEE) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - 天気ルール行

private struct WeatherRuleRow: View {
    @Bindable var rule: AlarmAdjustmentRule

    var body: some View {
        if let condition = rule.weatherCondition {
            HStack {
                Image(systemName: condition.iconName)
                    .foregroundStyle(condition.color)
                    .frame(width: 24)

                Text(condition.displayName)

                Spacer()

                Toggle("", isOn: $rule.isEnabled)
                    .labelsHidden()
                    .tint(AsaColors.coffeeBrown)
            }

            if rule.isEnabled {
                HStack {
                    Text("調整時間")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper(
                        "\(rule.adjustmentMinutes)分",
                        value: $rule.adjustmentMinutes,
                        in: 0...60,
                        step: 5
                    )
                    .labelsHidden()

                    Text("\(rule.adjustmentMinutes)分早く")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("アラーム詳細") {
    AlarmDetailView(
        alarm: .preview,
        calculation: .previewWithAdjustments,
        onSave: { _ in },
        onDelete: {}
    )
}
