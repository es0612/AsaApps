//
//  SettingsView.swift
//  AsaSmartTodo
//
//  メイン設定画面
//  AI予測、通知、カテゴリの設定を統括
//

import SwiftUI
import AsaUIKit

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                // アプリ情報セクション
                Section {
                    AppInfoRow()
                }

                // AI予測設定
                Section("AI予測設定") {
                    NavigationLink {
                        AIPredictionWeightsView(viewModel: viewModel)
                    } label: {
                        SettingsRow(
                            title: "AI予測の重み設定",
                            subtitle: "6要因の重み付けをカスタマイズ",
                            icon: "brain.head.profile",
                            color: AsaColors.coffeeBrown
                        )
                    }
                }

                // 通知設定
                Section("通知") {
                    SettingsRow(
                        title: "通知を有効化",
                        subtitle: viewModel.notificationAuthStatus == .authorized
                            ? "タスク期限をリマインド"
                            : "通知権限が必要です",
                        icon: "bell.fill",
                        color: AsaColors.mocha
                    ) {
                        Toggle("", isOn: Binding(
                            get: { viewModel.settings.notificationsEnabled },
                            set: { newValue in
                                viewModel.settings.notificationsEnabled = newValue
                                Task {
                                    await viewModel.toggleNotifications()
                                }
                            }
                        ))
                        .labelsHidden()
                        .disabled(viewModel.notificationAuthStatus != .authorized)
                    }

                    if viewModel.notificationAuthStatus == .notDetermined {
                        Button {
                            Task {
                                await viewModel.requestNotificationPermission()
                            }
                        } label: {
                            SettingsRow(
                                title: "通知権限をリクエスト",
                                subtitle: "通知を許可してください",
                                icon: "bell.badge.fill",
                                color: AsaColors.mutedSage
                            )
                        }
                    } else if viewModel.notificationAuthStatus == .denied {
                        Button {
                            viewModel.openNotificationSettings()
                        } label: {
                            SettingsRow(
                                title: "設定アプリで許可",
                                subtitle: "通知設定を変更してください",
                                icon: "gearshape.fill",
                                color: .orange
                            )
                        }
                    }

                    if viewModel.settings.notificationsEnabled &&
                       viewModel.notificationAuthStatus == .authorized {
                        NavigationLink {
                            NotificationSettingsView(viewModel: viewModel)
                        } label: {
                            SettingsRow(
                                title: "通知設定の詳細",
                                subtitle: "リマインダーの時間を変更",
                                icon: "clock.fill",
                                color: AsaColors.darkSlate
                            )
                        }
                    }
                }

                // カテゴリ管理
                Section("カテゴリ") {
                    NavigationLink {
                        CategoryManagementView(viewModel: viewModel)
                    } label: {
                        SettingsRow(
                            title: "カテゴリカスタマイズ",
                            subtitle: "独自カテゴリの追加・編集",
                            icon: "folder.fill",
                            color: AsaColors.mutedSage
                        )
                    }
                }

                // アプリ情報
                Section("アプリ情報") {
                    Link(destination: URL(string: "https://github.com/es0612/AsaApps")!) {
                        SettingsRow(
                            title: "GitHub",
                            subtitle: "ソースコードを見る",
                            icon: "link",
                            color: AsaColors.coffeeBrown
                        )
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                await viewModel.updateNotificationStatus()
            }
        }
    }
}

// MARK: - App Info Row

struct AppInfoRow: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.largeTitle)
                .foregroundColor(AsaColors.coffeeBrown)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(AsaColors.coffeeBrown.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("AsaSmartTodo")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AsaColors.darkSlate)

                Text("AIで優先度を提案するタスク管理")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.7))

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Row Component

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.content = content
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AsaColors.darkSlate)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate.opacity(0.6))
                }
            }

            Spacer()

            content()
        }
        .padding(.vertical, 2)
    }
}
