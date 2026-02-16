import Foundation

// MARK: - 学習ViewModel

@MainActor
@Observable
public final class LearningViewModel {
    // MARK: - Supporting Types

    public struct LearningItem: Identifiable, Sendable {
        public var id: UUID
        public var title: String
        public var category: String
        public var completedAt: Date

        public init(id: UUID = UUID(), title: String, category: String, completedAt: Date = Date()) {
            self.id = id
            self.title = title
            self.category = category
            self.completedAt = completedAt
        }
    }

    // MARK: - Properties

    public var studyStreak: Int = 0
    public var recentLearning: [LearningItem] = []
    public var weeklyHeatmap: [Date: Int] = [:]
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadLearningData() async {
        isLoading = true
        error = nil
        do {
            let calendar = Calendar.current
            let today = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            let dashboards = try await dataService.fetchDashboards(from: weekAgo, to: today)

            studyStreak = 0
            for dashboard in dashboards.sorted(by: { $0.date > $1.date }) {
                if dashboard.activeDomains.contains(.learning) {
                    studyStreak += 1
                } else {
                    break
                }
            }

            for dashboard in dashboards {
                let day = calendar.startOfDay(for: dashboard.date)
                weeklyHeatmap[day] = dashboard.morningScore > 0 ? 1 : 0
            }

            if recentLearning.isEmpty {
                recentLearning = [
                    LearningItem(title: "SwiftUI アニメーション", category: "iOS開発"),
                    LearningItem(title: "Swift Concurrency", category: "iOS開発"),
                    LearningItem(title: "ビジネス英語", category: "語学"),
                ]
            }
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }
}
