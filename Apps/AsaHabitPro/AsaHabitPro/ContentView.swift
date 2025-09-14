import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HabitViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
                .tag(0)

            HabitListView(viewModel: viewModel)
                .tabItem {
                    Label("習慣", systemImage: "list.bullet")
                }
                .tag(1)

            ChartsView(viewModel: viewModel)
                .tabItem {
                    Label("グラフ", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            StatisticsView(viewModel: viewModel)
                .tabItem {
                    Label("統計", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
        .tint(Color("AsaCoffeeBrown"))
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .task {
            // 初回起動時にサンプルデータがなければ作成
            if viewModel.habits.isEmpty {
                await viewModel.createSampleData()
            }
        }
    }
}