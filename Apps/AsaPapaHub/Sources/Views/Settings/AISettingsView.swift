import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - AI設定ビュー

/// AI機能の有効・無効を切り替える設定
struct AISettingsView: View {
    @Binding var preferences: HubUserPreferences?

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle(isOn: aiEnabledBinding) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI機能")
                                .font(.body)
                            Text("AIブリーフィングや提案を有効にします")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
                .tint(AsaColors.coffeeBrown)
            } header: {
                Text("AI機能")
            }

            Section {
                InfoRow(title: "AIブリーフィング", description: "毎朝のAI生成ブリーフィングを表示")
                InfoRow(title: "インサイト分析", description: "健康・学習データのAI分析")
                InfoRow(title: "スマート提案", description: "ルーティン改善のための提案")
            } header: {
                Text("AI機能の内容")
            } footer: {
                Text("AI機能はデバイス上で処理されます。データはサーバーに送信されません。")
            }
        }
        .navigationTitle("AI設定")
    }

    // MARK: - Private

    private var aiEnabledBinding: Binding<Bool> {
        Binding(
            get: { preferences?.aiEnabled ?? true },
            set: { newValue in
                preferences?.aiEnabled = newValue
                preferences?.updatedAt = Date()
            }
        )
    }
}

// MARK: - 情報行

private struct InfoRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
