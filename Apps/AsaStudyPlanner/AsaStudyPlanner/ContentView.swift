import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "dashboard"
        case items = "items"
        case session = "session"
        case analytics = "analytics"
        case settings = "settings"

        var title: String {
            switch self {
            case .dashboard: return "ダッシュボード"
            case .items: return "学習項目"
            case .session: return "セッション"
            case .analytics: return "分析"
            case .settings: return "設定"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .items: return "book.fill"
            case .session: return "timer"
            case .analytics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            StudyItemListView()
                .tabItem {
                    Label(Tab.items.title, systemImage: Tab.items.icon)
                }
                .tag(Tab.items)

            SessionView()
                .tabItem {
                    Label(Tab.session.title, systemImage: Tab.session.icon)
                }
                .tag(Tab.session)

            AnalyticsView()
                .tabItem {
                    Label(Tab.analytics.title, systemImage: Tab.analytics.icon)
                }
                .tag(Tab.analytics)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(Color("AsaCoffeeBrown"))
        #if DEBUG
        .onAppear {
            SampleDataLoader.loadIfNeeded(context: modelContext)
        }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
