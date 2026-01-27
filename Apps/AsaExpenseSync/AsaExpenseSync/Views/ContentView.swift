import SwiftUI
import AsaUIKit

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case transactions
        case reports
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            TransactionListView()
                .tabItem {
                    Label("取引", systemImage: "list.bullet")
                }
                .tag(Tab.transactions)

            ReportsView()
                .tabItem {
                    Label("レポート", systemImage: "chart.pie.fill")
                }
                .tag(Tab.reports)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(AsaColors.coffeeBrown)
        .onAppear {
            loadDataIfNeeded()
        }
    }

    private func loadDataIfNeeded() {
        guard let userId = authViewModel.currentUser?.id else { return }

        Task {
            await expenseViewModel.loadData(userId: userId)
            expenseViewModel.startObserving(userId: userId)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
