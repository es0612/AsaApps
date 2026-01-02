//
//  NotificationSettingsView.swift
//  AsaSmartTodo
//
//  通知詳細設定画面
//  期限日、1日前、朝活リマインダーの時間設定
//

import SwiftUI
import AsaUIKit

struct NotificationSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section("リマインダータイミング") {
                Toggle("期限日当日", isOn: $viewModel.settings.dueDayReminderEnabled)
                Toggle("1日前", isOn: $viewModel.settings.oneDayBeforeReminderEnabled)
            }

            Section("通知時刻") {
                HStack {
                    Text("時間")
                    Spacer()
                    Picker("時", selection: $viewModel.settings.notificationHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)時").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 100)
                }

                HStack {
                    Text("分")
                    Spacer()
                    Picker("分", selection: $viewModel.settings.notificationMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 100)
                }
            }

            Section {
                Text("タスク期限の\(String(format: "%02d:%02d", viewModel.settings.notificationHour, viewModel.settings.notificationMinute))にリマインダーが送信されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("朝活リマインダー") {
                Toggle("朝活リマインダー", isOn: $viewModel.settings.morningReminderEnabled)

                if viewModel.settings.morningReminderEnabled {
                    DatePicker(
                        "時刻",
                        selection: $viewModel.settings.morningReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section {
                Text("朝活時間帯（5:00-7:00）にタスクを確認するリマインダーを毎日送信します。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("通知設定の詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.saveSettings()
                    Task {
                        await viewModel.scheduleMorningReminder()
                    }
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }
}
