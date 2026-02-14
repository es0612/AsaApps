import SwiftUI
import SwiftData
import AsaUIKit
import AsaCommunityKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var hasLoadedSampleData = false

    enum Tab: String, CaseIterable {
        case home = "ホーム"
        case feed = "掲示板"
        case events = "イベント"
        case map = "マップ"
        case safety = "防災"

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .feed: return "bubble.left.and.bubble.right.fill"
            case .events: return "calendar"
            case .map: return "map.fill"
            case .safety: return "shield.checkered"
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
            await loadSampleDataIfNeeded()
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        let dataService = CommunityDataService(modelContext: modelContext)
        let notificationService = NotificationService()
        let locationService = LocationService()

        switch tab {
        case .home:
            CommunityHomeView(
                viewModel: CommunityHomeViewModel(
                    dataService: dataService
                )
            )
        case .feed:
            PostFeedView(
                viewModel: PostFeedViewModel(
                    dataService: dataService,
                    moderator: ContentModerationService()
                )
            )
        case .events:
            EventCalendarView(
                viewModel: EventCalendarViewModel(
                    dataService: dataService,
                    notificationService: notificationService
                )
            )
        case .map:
            NeighborhoodMapView(
                viewModel: NeighborhoodMapViewModel(
                    dataService: dataService,
                    locationService: locationService
                )
            )
        case .safety:
            SafetyDashboardView(
                viewModel: SafetyViewModel(
                    dataService: dataService,
                    notificationService: notificationService
                )
            )
        }
    }

    private func loadSampleDataIfNeeded() async {
        guard !hasLoadedSampleData else { return }
        hasLoadedSampleData = true

        let dataService = CommunityDataService(modelContext: modelContext)
        do {
            let existingCommunity = try dataService.fetchCommunity()
            if existingCommunity == nil {
                let sampleService = SampleDataService(modelContext: modelContext)
                try sampleService.loadSampleData()
            }
        } catch {
            print("サンプルデータ読み込みエラー: \(error.localizedDescription)")
        }
    }
}
