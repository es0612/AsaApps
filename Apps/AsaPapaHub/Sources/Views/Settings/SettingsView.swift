import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 設定ビュー

/// アプリ設定画面
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var preferences: HubUserPreferences?

    // MARK: - Body

    var body: some View {
        List {
            // ドメイン設定
            Section {
                NavigationLink {
                    DomainSettingsView(preferences: $preferences)
                } label: {
                    Label("ドメイン設定", systemImage: "square.grid.2x2")
                }
            } header: {
                Text("カスタマイズ")
            }

            // AI設定
            Section {
                NavigationLink {
                    AISettingsView(preferences: $preferences)
                } label: {
                    Label("AI機能", systemImage: "sparkles")
                }
            } header: {
                Text("AI")
            }

            // 通知設定
            Section {
                NavigationLink {
                    NotificationSettingsView(preferences: $preferences)
                } label: {
                    Label("通知設定", systemImage: "bell")
                }
            } header: {
                Text("通知")
            }

            // 一般
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("このアプリについて", systemImage: "info.circle")
                }
            } header: {
                Text("一般")
            }

            // データ管理
            Section {
                Button(role: .destructive) {
                    resetSampleData()
                } label: {
                    Label("サンプルデータをリセット", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("データ管理")
            } footer: {
                Text("サンプルデータを再生成します。既存のデータは保持されます。")
            }
        }
        .navigationTitle("設定")
        .task { await loadPreferences() }
    }

    // MARK: - Private

    private func loadPreferences() async {
        let descriptor = FetchDescriptor<HubUserPreferences>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        preferences = try? modelContext.fetch(descriptor).first
    }

    private func resetSampleData() {
        UserDefaults.standard.removeObject(forKey: "SampleDataLoaded_v1")
        let loader = SampleDataLoader(modelContext: modelContext)
        Task {
            await loader.loadIfNeeded()
        }
    }
}
