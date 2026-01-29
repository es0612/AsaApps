import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BudgetAIViewModel?
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "dashboard"
        case transactions = "transactions"
        case analytics = "analytics"
        case insights = "insights"
        case settings = "settings"

        var title: String {
            switch self {
            case .dashboard: return "ホーム"
            case .transactions: return "取引"
            case .analytics: return "分析"
            case .insights: return "AI洞察"
            case .settings: return "設定"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .transactions: return "list.bullet.rectangle.portrait"
            case .analytics: return "chart.bar.fill"
            case .insights: return "brain.head.profile"
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
                            Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                        }
                        .tag(Tab.dashboard)

                    TransactionListView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.transactions.title, systemImage: Tab.transactions.icon)
                        }
                        .tag(Tab.transactions)

                    AnalyticsView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.analytics.title, systemImage: Tab.analytics.icon)
                        }
                        .tag(Tab.analytics)

                    AIInsightsView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.insights.title, systemImage: Tab.insights.icon)
                        }
                        .tag(Tab.insights)

                    SettingsView(viewModel: viewModel)
                        .tabItem {
                            Label(Tab.settings.title, systemImage: Tab.settings.icon)
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
        do {
            let container = try DataService.createContainer()
            let dataService = DataService(modelContainer: container)
            viewModel = BudgetAIViewModel(dataService: dataService)
        } catch {
            print("Failed to initialize: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
