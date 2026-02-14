import SwiftUI
import SwiftData
import AsaLifeLogKit

// MARK: - ContentView

/// メインコンテンツビュー（4タブ構成）
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    // サービス
    @State private var dataService: LifeLogDataService?
    @State private var timelineService = TimelineService()
    @State private var insightsEngine = InsightsEngine()

    var body: some View {
        Group {
            if let dataService {
                TabView(selection: $selectedTab) {
                    TimelineView(
                        viewModel: TimelineViewModel(
                            dataService: dataService,
                            timelineService: timelineService
                        ),
                        editorViewModel: EntryEditorViewModel(
                            dataService: dataService
                        )
                    )
                    .tabItem {
                        Label("タイムライン", systemImage: "clock")
                    }
                    .tag(0)

                    DashboardView(
                        viewModel: DashboardViewModel(
                            dataService: dataService,
                            insightsEngine: insightsEngine
                        )
                    )
                    .tabItem {
                        Label("ダッシュボード", systemImage: "chart.bar")
                    }
                    .tag(1)

                    InsightsView(
                        viewModel: InsightsViewModel(
                            dataService: dataService,
                            insightsEngine: insightsEngine
                        )
                    )
                    .tabItem {
                        Label("インサイト", systemImage: "lightbulb")
                    }
                    .tag(2)

                    SettingsView(
                        viewModel: SettingsViewModel(
                            dataService: dataService
                        ),
                        placeLogViewModel: PlaceLogViewModel(
                            dataService: dataService
                        )
                    )
                    .tabItem {
                        Label("設定", systemImage: "gear")
                    }
                    .tag(3)
                }
                .tint(Color("AccentColor"))
            } else {
                ProgressView("読み込み中...")
            }
        }
        .task {
            dataService = LifeLogDataService(modelContext: modelContext)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}
