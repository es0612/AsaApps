import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - ContentView

/// メインコンテンツビュー（5タブ構成）
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var isInitialized = false
    @State private var showOnboarding = false
    @State private var aiService = PapaHubAIService()

    var body: some View {
        Group {
            if isInitialized {
                mainTabView
            } else {
                loadingView
            }
        }
        .task {
            await initializeApp()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }

    // MARK: - Private Views

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // タブ0: ホームダッシュボード
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("ホーム", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)

            // タブ1: 朝活ルーティン
            NavigationStack {
                MorningRoutineView()
            }
            .tabItem {
                Label("朝活", systemImage: "sunrise.fill")
            }
            .tag(1)

            // タブ2: AI検索
            NavigationStack {
                AISearchView(aiService: aiService)
                    .navigationTitle("AI検索")
            }
            .tabItem {
                Label("AI検索", systemImage: "sparkle.magnifyingglass")
            }
            .tag(2)

            // タブ3: インサイトハブ
            NavigationStack {
                InsightsHubView()
            }
            .tabItem {
                Label("インサイト", systemImage: "chart.bar.fill")
            }
            .tag(3)

            // タブ4: 設定
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gear")
            }
            .tag(4)
        }
        .tint(AsaColors.coffeeBrown)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("AsaPapaHub")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AsaColors.coffeeBrown)
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Private Methods

    private func initializeApp() async {
        // 初回起動時にサンプルデータを投入
        let loader = SampleDataLoader(modelContext: modelContext)
        await loader.loadIfNeeded()

        // オンボーディング表示チェック
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        if !hasSeenOnboarding {
            showOnboarding = true
        }

        isInitialized = true
    }
}

// MARK: - インサイトハブ

/// 各ドメインの詳細ビューへのハブ
struct InsightsHubView: View {
    var body: some View {
        List {
            ForEach(LifeDomain.allCases, id: \.self) { domain in
                NavigationLink {
                    domainDetailView(for: domain)
                } label: {
                    Label {
                        Text(domain.displayName)
                    } icon: {
                        Image(systemName: domain.icon)
                            .foregroundStyle(Color(hex: domain.accentColorHex))
                    }
                }
            }
        }
        .navigationTitle("インサイト")
    }

    @ViewBuilder
    private func domainDetailView(for domain: LifeDomain) -> some View {
        switch domain {
        case .morning:
            MorningScoreDetailView()
        case .health:
            HealthOverviewView()
        case .family:
            FamilyHubView()
        case .finance:
            FinanceOverviewView()
        case .community:
            CommunityOverviewView()
        case .learning:
            LearningOverviewView()
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
