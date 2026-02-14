import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// プロフィール・設定画面
struct ProfileSettingsView: View {
    @Bindable var viewModel: ProfileSettingsViewModel

    var body: some View {
        Form {
            // MARK: - Profile
            Section("プロフィール") {
                if let profile = viewModel.profile {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AsaColors.coffeeBrown)
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                                .font(.headline)
                            Text("参加日: \(profile.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                Label("\(profile.postCount) 投稿", systemImage: "text.bubble")
                                Label("\(profile.helpfulCount) お役立ち", systemImage: "hand.thumbsup")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("プロフィールを設定してください")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Notifications
            Section("通知設定") {
                if let settings = viewModel.settings {
                    Toggle("ゴミ出しリマインダー", isOn: Binding(
                        get: { settings.isGarbageReminderEnabled },
                        set: { newValue in
                            settings.isGarbageReminderEnabled = newValue
                            Task { await viewModel.saveSettings() }
                        }
                    ))
                    .tint(AsaColors.coffeeBrown)

                    if settings.isGarbageReminderEnabled {
                        HStack {
                            Text("通知時刻")
                            Spacer()
                            Text("前夜 \(settings.reminderHour):00")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("イベント通知", isOn: Binding(
                        get: { settings.isEventNotificationEnabled },
                        set: { newValue in
                            settings.isEventNotificationEnabled = newValue
                            Task { await viewModel.saveSettings() }
                        }
                    ))
                    .tint(AsaColors.coffeeBrown)

                    Toggle("安全アラート", isOn: Binding(
                        get: { settings.isSafetyAlertEnabled },
                        set: { newValue in
                            settings.isSafetyAlertEnabled = newValue
                            Task { await viewModel.saveSettings() }
                        }
                    ))
                    .tint(AsaColors.coffeeBrown)
                }
            }

            // MARK: - Map Settings
            Section("マップ設定") {
                if let settings = viewModel.settings {
                    Picker("表示半径", selection: Binding(
                        get: { settings.mapRadiusMeters },
                        set: { newValue in
                            settings.mapRadiusMeters = newValue
                            Task { await viewModel.saveSettings() }
                        }
                    )) {
                        Text("500m").tag(500)
                        Text("1km").tag(1000)
                        Text("2km").tag(2000)
                        Text("5km").tag(5000)
                    }
                }
            }

            // MARK: - Theme
            Section("テーマ") {
                if let settings = viewModel.settings {
                    Picker("テーマ", selection: Binding(
                        get: { settings.theme },
                        set: { newValue in
                            settings.theme = newValue
                            Task { await viewModel.saveSettings() }
                        }
                    )) {
                        ForEach(CommunitySettings.Theme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            // MARK: - About
            Section("このアプリについて") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("開発者")
                    Spacer()
                    Text("AsaApps")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("設定")
        .onAppear {
            viewModel.loadProfileAndSettings()
        }
    }
}
