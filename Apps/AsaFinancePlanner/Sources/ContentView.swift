import SwiftUI
import SwiftData
import AsaUIKit
import AsaFinancePlannerKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "ダッシュボード"
        case goals = "目標"
        case allocation = "配分"
        case projection = "予測"
        case settings = "設定"

        var iconName: String {
            switch self {
            case .dashboard: return "house.fill"
            case .goals: return "target"
            case .allocation: return "chart.pie.fill"
            case .projection: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.iconName)
                    }
                    .tag(tab)
            }
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            loadSampleDataIfNeeded()
        }
    }

    /// 初回起動時にデモ用サンプルデータを投入
    private func loadSampleDataIfNeeded() {
        let key = "AsaFinancePlanner_SampleDataLoaded_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let service = SampleDataService(modelContext: modelContext)
        do {
            try service.loadSampleData()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(
                viewModel: DashboardViewModel(
                    dataService: FinanceDataService(modelContext: modelContext)
                )
            )
        case .goals:
            GoalListView(
                viewModel: GoalViewModel(
                    dataService: FinanceDataService(modelContext: modelContext)
                )
            )
        case .allocation:
            AllocationView(
                viewModel: AllocationViewModel(
                    dataService: FinanceDataService(modelContext: modelContext)
                )
            )
        case .projection:
            ProjectionView(
                viewModel: ProjectionViewModel(
                    dataService: FinanceDataService(modelContext: modelContext)
                )
            )
        case .settings:
            SettingsView(
                viewModel: SettingsViewModel(
                    dataService: FinanceDataService(modelContext: modelContext)
                )
            )
        }
    }
}
