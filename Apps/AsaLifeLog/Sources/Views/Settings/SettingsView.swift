import SwiftUI
import AsaLifeLogKit

// MARK: - SettingsView

/// 設定ビュー
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Bindable var placeLogViewModel: PlaceLogViewModel

    var body: some View {
        NavigationStack {
            Form {
                // データソース
                Section("データソース") {
                    DataSourceToggle(
                        title: "ヘルスケア",
                        icon: "heart.fill",
                        iconColor: .red,
                        isOn: Binding(
                            get: { viewModel.preferences?.enableHealthTracking ?? false },
                            set: { _ in Task { await viewModel.toggleHealthTracking() } }
                        )
                    )

                    DataSourceToggle(
                        title: "位置情報",
                        icon: "location.fill",
                        iconColor: .blue,
                        isOn: Binding(
                            get: { viewModel.preferences?.enableLocationTracking ?? false },
                            set: { _ in Task { await viewModel.toggleLocationTracking() } }
                        )
                    )

                    DataSourceToggle(
                        title: "写真",
                        icon: "photo.fill",
                        iconColor: .purple,
                        isOn: Binding(
                            get: { viewModel.preferences?.enablePhotoIntegration ?? false },
                            set: { _ in Task { await viewModel.togglePhotoIntegration() } }
                        )
                    )

                    DataSourceToggle(
                        title: "アクティビティ",
                        icon: "figure.walk",
                        iconColor: .green,
                        isOn: Binding(
                            get: { viewModel.preferences?.enableActivityRecognition ?? false },
                            set: { _ in Task { await viewModel.toggleActivityRecognition() } }
                        )
                    )

                    DataSourceToggle(
                        title: "AIインサイト",
                        icon: "brain.head.profile",
                        iconColor: .orange,
                        isOn: Binding(
                            get: { viewModel.preferences?.enableAIInsights ?? false },
                            set: { _ in Task { await viewModel.toggleAIInsights() } }
                        )
                    )
                }

                // 場所
                Section("場所") {
                    NavigationLink {
                        PlaceListView(viewModel: placeLogViewModel)
                    } label: {
                        Label("訪問場所一覧", systemImage: "mappin.and.ellipse")
                    }

                    NavigationLink {
                        PlaceMapView(viewModel: placeLogViewModel)
                    } label: {
                        Label("マップで表示", systemImage: "map")
                    }
                }

                // エクスポート
                Section("データ管理") {
                    NavigationLink {
                        ExportView(viewModel: viewModel)
                    } label: {
                        Label("データエクスポート", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        GoalSettings(viewModel: viewModel)
                    } label: {
                        Label("目標設定", systemImage: "target")
                    }
                }

                // アプリ情報
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("AsaLifeLogについて", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("設定")
            .task {
                await viewModel.loadPreferences()
            }
        }
    }
}
