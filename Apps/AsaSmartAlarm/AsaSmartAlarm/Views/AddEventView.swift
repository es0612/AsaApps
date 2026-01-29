//
//  AddEventView.swift
//  AsaSmartAlarm
//
//  イベント追加画面
//

import SwiftUI

// MARK: - イベント追加ビュー

/// 新しいイベントを追加する画面
struct AddEventView: View {
    // MARK: - Properties

    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var startTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    @State private var location: String = ""
    @State private var preparationMinutes: Int = 30
    @State private var travelMinutes: Int = 30
    @State private var priority: EventPriority = .medium
    @State private var isAllDay: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("タイトル", text: $title)

                    Toggle("終日", isOn: $isAllDay)

                    if isAllDay {
                        DatePicker(
                            "日付",
                            selection: $startTime,
                            displayedComponents: .date
                        )
                    } else {
                        DatePicker(
                            "日時",
                            selection: $startTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    TextField("場所（オプション）", text: $location)
                }

                // 準備時間
                Section {
                    Stepper(
                        "準備時間: \(preparationMinutes)分",
                        value: $preparationMinutes,
                        in: 0...120,
                        step: 5
                    )

                    Stepper(
                        "移動時間: \(travelMinutes)分",
                        value: $travelMinutes,
                        in: 0...120,
                        step: 5
                    )

                    // 推奨起床時刻
                    if !isAllDay {
                        HStack {
                            Text("推奨起床時刻")
                            Spacer()
                            Text(suggestedWakeUpTimeString)
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("準備時間")
                } footer: {
                    Text("この予定のために必要な準備時間と移動時間を設定します。アラームの自動調整に使用されます。")
                }

                // 優先度
                Section("優先度") {
                    Picker("優先度", selection: $priority) {
                        ForEach(EventPriority.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // プリセット
                Section("クイック設定") {
                    PresetRow(
                        title: "通勤（30分準備 + 45分移動）",
                        icon: "tram.fill"
                    ) {
                        preparationMinutes = 30
                        travelMinutes = 45
                    }

                    PresetRow(
                        title: "在宅ワーク（15分準備）",
                        icon: "house.fill"
                    ) {
                        preparationMinutes = 15
                        travelMinutes = 0
                    }

                    PresetRow(
                        title: "近場の予定（20分準備 + 15分移動）",
                        icon: "figure.walk"
                    ) {
                        preparationMinutes = 20
                        travelMinutes = 15
                    }
                }
            }
            .navigationTitle("予定を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var suggestedWakeUpTimeString: String {
        let totalMinutes = preparationMinutes + travelMinutes
        let wakeUpTime = startTime.addingTimeInterval(TimeInterval(-totalMinutes * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeUpTime)
    }

    // MARK: - Private Methods

    private func saveEvent() {
        Task {
            await viewModel.addEvent(
                title: title,
                startTime: startTime,
                location: location.isEmpty ? nil : location,
                preparationMinutes: preparationMinutes,
                travelMinutes: travelMinutes,
                priority: priority,
                isAllDay: isAllDay
            )
            dismiss()
        }
    }
}

// MARK: - プリセット行

private struct PresetRow: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
    }
}

// MARK: - Preview

#Preview("イベント追加") {
    AddEventView(viewModel: .preview)
}
