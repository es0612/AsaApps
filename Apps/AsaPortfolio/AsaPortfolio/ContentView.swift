import SwiftUI
import SwiftData
import AsaUIKit

/// メインコンテンツビュー - TabViewでナビゲーション
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PortfolioViewModel?
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "ダッシュボード"
        case portfolio = "ポートフォリオ"
        case watchlist = "ウォッチリスト"
        case analytics = "分析"
        case settings = "設定"

        var icon: String {
            switch self {
            case .dashboard: return "chart.pie.fill"
            case .portfolio: return "briefcase.fill"
            case .watchlist: return "star.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel = viewModel {
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                        }
                        .tag(Tab.dashboard)

                    PortfolioListView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.portfolio.rawValue, systemImage: Tab.portfolio.icon)
                        }
                        .tag(Tab.portfolio)

                    WatchlistView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.watchlist.rawValue, systemImage: Tab.watchlist.icon)
                        }
                        .tag(Tab.watchlist)

                    AnalyticsView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.analytics.rawValue, systemImage: Tab.analytics.icon)
                        }
                        .tag(Tab.analytics)

                    SettingsView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                        }
                        .tag(Tab.settings)
                }
                .tint(AsaColors.coffeeBrown)
            } else {
                ProgressView("読み込み中...")
                    .onAppear {
                        initializeViewModel()
                    }
            }
        }
    }

    private func initializeViewModel() {
        let apiService = MockStockAPIService()
        let dataService = PortfolioDataService(modelContext: modelContext)
        viewModel = PortfolioViewModel(
            stockAPIService: apiService,
            dataService: dataService
        )

        Task {
            await viewModel?.loadInitialData()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Portfolio.self,
            Holding.self,
            Transaction.self,
            Dividend.self,
            WatchlistItem.self
        ], inMemory: true)
}
