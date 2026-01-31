import SwiftUI

// MARK: - SettingsView

/// 設定画面
struct SettingsView: View {
    // MARK: - Properties

    @Bindable var viewModel: SmartHomeViewModel
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 接続状態
                Section {
                    connectionStatusRow
                }

                // 一般設定
                Section("一般") {
                    Toggle("自動更新", isOn: $autoRefreshEnabled)
                    Toggle("通知", isOn: $notificationsEnabled)
                    Toggle("ダークモード", isOn: $darkModeEnabled)
                }

                // デバイス統計
                Section("デバイス統計") {
                    deviceStatsRows
                }

                // データ管理
                Section("データ管理") {
                    Button("キャッシュをクリア") {
                        // キャッシュクリア処理
                    }
                    .foregroundStyle(Color.asaCoffeeBrown)

                    Button("すべてのデータをリセット", role: .destructive) {
                        // データリセット処理
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
                        Text("ビルド")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                }

                // 開発者情報
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("AsaSmartHome")
                            .font(.headline)

                        Text("朝活パパエンジニア")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("100 SwiftUI Apps Challenge #87")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var connectionStatusRow: some View {
        HStack {
            Image(systemName: viewModel.isConnected ? "wifi" : "wifi.slash")
                .foregroundStyle(viewModel.isConnected ? Color.deviceOnline : Color.deviceOffline)

            Text("接続状態")

            Spacer()

            Text(viewModel.isConnected ? "接続中" : "切断")
                .foregroundStyle(viewModel.isConnected ? Color.deviceOnline : Color.deviceOffline)
        }
    }

    @ViewBuilder
    private var deviceStatsRows: some View {
        HStack {
            Text("登録デバイス数")
            Spacer()
            Text("\(viewModel.devices.count)")
                .foregroundStyle(.secondary)
        }

        HStack {
            Text("オンラインデバイス")
            Spacer()
            Text("\(viewModel.onlineDeviceCount)")
                .foregroundStyle(.secondary)
        }

        HStack {
            Text("アクティブデバイス")
            Spacer()
            Text("\(viewModel.activeDeviceCount)")
                .foregroundStyle(.secondary)
        }

        HStack {
            Text("部屋数")
            Spacer()
            Text("\(viewModel.rooms.count)")
                .foregroundStyle(.secondary)
        }

        HStack {
            Text("シーン数")
            Spacer()
            Text("\(viewModel.scenes.count)")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    Text("Settings Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
