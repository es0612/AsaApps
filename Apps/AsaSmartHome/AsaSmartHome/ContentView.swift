import SwiftUI

// MARK: - ContentView

/// メインコンテンツビュー（タブ構成）
struct ContentView: View {
    // MARK: - Properties

    @State var viewModel: SmartHomeViewModel
    @State private var selectedTab: Tab = .dashboard

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case dashboard = "ダッシュボード"
        case rooms = "部屋"
        case scenes = "シーン"
        case settings = "設定"

        var iconName: String {
            switch self {
            case .dashboard: return "house.fill"
            case .rooms: return "rectangle.split.3x1.fill"
            case .scenes: return "sparkles.rectangle.stack.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.appState {
            case .loading:
                loadingView

            case .ready:
                mainTabView

            case .error(let message):
                errorView(message: message)
            }
        }
        .task {
            await viewModel.initialize()
        }
    }

    // MARK: - Main Tab View

    @ViewBuilder
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.iconName)
                }
                .tag(Tab.dashboard)

            RoomListView(viewModel: viewModel)
                .tabItem {
                    Label(Tab.rooms.rawValue, systemImage: Tab.rooms.iconName)
                }
                .tag(Tab.rooms)

            SceneListView(viewModel: viewModel)
                .tabItem {
                    Label(Tab.scenes.rawValue, systemImage: Tab.scenes.iconName)
                }
                .tag(Tab.scenes)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .tint(Color.asaCoffeeBrown)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.asaDarkSlate
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // アプリアイコン
                ZStack {
                    Circle()
                        .fill(Color.asaCoffeeBrown.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "house.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }

                Text("スマートホームに接続中...")
                    .font(.headline)
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(Color.asaCoffeeBrown)
                    .scaleEffect(1.2)
            }
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        ZStack {
            Color.asaDarkSlate
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.deviceOffline)

                Text("接続エラー")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    Task {
                        await viewModel.initialize()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再試行")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.asaCoffeeBrown)
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Content View") {
    Text("Content View Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
