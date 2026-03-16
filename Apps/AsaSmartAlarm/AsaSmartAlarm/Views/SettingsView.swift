//
//  SettingsView.swift
//  AsaSmartAlarm
//
//  設定画面
//

import SwiftUI
import AsaUIKit

// MARK: - 設定ビュー

/// アプリの設定を管理する画面
struct SettingsView: View {
    // MARK: - Properties

    var settings: AlarmSettings?
    @Environment(\.dismiss) private var dismiss

    @State private var notificationStatus: String = "確認中..."
    @State private var locationStatus: String = "確認中..."

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 通知設定
                Section {
                    HStack {
                        Label("通知", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundStyle(.secondary)
                    }

                    if let settings = settings {
                        Toggle(isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { settings.notificationsEnabled = $0 }
                        )) {
                            Text("アラーム通知を有効にする")
                        }
                        .tint(AsaColors.coffeeBrown)
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("通知が無効の場合、アラームが鳴りません。設定アプリから通知を許可してください。")
                }

                // スヌーズ設定
                if let settings = settings {
                    Section("スヌーズ") {
                        Picker("スヌーズ時間", selection: Binding(
                            get: { settings.snoozeMinutes },
                            set: { settings.snoozeMinutes = $0 }
                        )) {
                            ForEach(SnoozeOption.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }

                        Stepper(
                            "最大スヌーズ回数: \(settings.maxSnoozeCount)回",
                            value: Binding(
                                get: { settings.maxSnoozeCount },
                                set: { settings.maxSnoozeCount = $0 }
                            ),
                            in: 1...10
                        )
                    }
                }

                // 天気設定
                Section {
                    HStack {
                        Label("位置情報", systemImage: "location.fill")
                        Spacer()
                        Text(locationStatus)
                            .foregroundStyle(.secondary)
                    }

                    if let settings = settings {
                        Toggle(isOn: Binding(
                            get: { settings.weatherUpdateEnabled },
                            set: { settings.weatherUpdateEnabled = $0 }
                        )) {
                            Text("天気の自動取得")
                        }
                        .tint(AsaColors.coffeeBrown)

                        Toggle(isOn: Binding(
                            get: { settings.useCurrentLocation },
                            set: { settings.useCurrentLocation = $0 }
                        )) {
                            Text("現在地を使用")
                        }
                        .tint(AsaColors.coffeeBrown)
                        .disabled(!settings.weatherUpdateEnabled)

                        if settings.hasSavedLocation {
                            HStack {
                                Text("保存された場所")
                                Spacer()
                                Text(settings.savedLocationName ?? "不明")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("天気")
                } footer: {
                    Text("天気情報を取得するために位置情報が必要です。")
                }

                // 表示設定
                if let settings = settings {
                    Section("表示") {
                        Toggle(isOn: Binding(
                            get: { settings.use24HourFormat },
                            set: { settings.use24HourFormat = $0 }
                        )) {
                            Text("24時間表示")
                        }
                        .tint(AsaColors.coffeeBrown)

                        Toggle(isOn: Binding(
                            get: { settings.showWeatherOnMainScreen },
                            set: { settings.showWeatherOnMainScreen = $0 }
                        )) {
                            Text("メイン画面に天気を表示")
                        }
                        .tint(AsaColors.coffeeBrown)

                        Toggle(isOn: Binding(
                            get: { settings.showNextEventOnMainScreen },
                            set: { settings.showNextEventOnMainScreen = $0 }
                        )) {
                            Text("メイン画面に次の予定を表示")
                        }
                        .tint(AsaColors.coffeeBrown)
                    }
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("開発者")
                        Spacer()
                        Text("朝活パパエンジニア")
                            .foregroundStyle(.secondary)
                    }
                }

                // リセット
                if settings != nil {
                    Section {
                        Button(role: .destructive) {
                            settings?.resetToDefaults()
                        } label: {
                            HStack {
                                Spacer()
                                Text("設定をリセット")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .task {
                await checkPermissions()
            }
        }
    }

    // MARK: - Private Methods

    private func checkPermissions() async {
        // 通知権限を確認
        let notificationService = NotificationService.shared
        let isAuthorized = await notificationService.isAuthorized()
        notificationStatus = isAuthorized ? "許可済み" : "未許可"

        // 位置情報の状態はLocationServiceから取得する必要があるが、
        // ここではシンプルに表示
        locationStatus = "確認してください"
    }
}

// MARK: - Preview

#Preview("設定") {
    SettingsView(settings: .default)
}
