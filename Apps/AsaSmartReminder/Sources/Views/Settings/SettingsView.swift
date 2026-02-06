import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - 設定ビュー

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let permissionService: PermissionService
    let monitoringState: MonitoringState

    var body: some View {
        NavigationStack {
            List {
                // 権限ステータスセクション
                Section("権限") {
                    PermissionStatusView(permissionService: permissionService)
                }

                // 監視状態セクション
                Section("監視状態") {
                    HStack {
                        Label("ステータス", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        MonitoringStatusBadge(state: monitoringState)
                    }
                }

                // デフォルト設定セクション
                Section("デフォルト設定") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("デフォルト半径")
                            Spacer()
                            Text(viewModel.radiusDisplayText)
                                .foregroundStyle(AsaColors.coffeeBrown)
                                .fontWeight(.medium)
                        }
                        Slider(value: $viewModel.defaultRadius, in: 10 ... 1000, step: 10)
                            .tint(AsaColors.coffeeBrown)
                            .onChange(of: viewModel.defaultRadius) {
                                viewModel.saveSettings()
                            }
                    }

                    Toggle("到着時に通知", isOn: $viewModel.defaultTriggerOnEntry)
                        .onChange(of: viewModel.defaultTriggerOnEntry) {
                            viewModel.saveSettings()
                        }
                    Toggle("離脱時に通知", isOn: $viewModel.defaultTriggerOnExit)
                        .onChange(of: viewModel.defaultTriggerOnExit) {
                            viewModel.saveSettings()
                        }
                }

                // その他セクション
                Section("その他") {
                    Toggle("触覚フィードバック", isOn: $viewModel.hapticFeedbackEnabled)
                        .onChange(of: viewModel.hapticFeedbackEnabled) {
                            viewModel.saveSettings()
                        }
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("開発者")
                        Spacer()
                        Text("朝活パパエンジニア")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}
