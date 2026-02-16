import Foundation

// MARK: - ダッシュボードViewModel

@MainActor
@Observable
public final class DashboardViewModel {
    // MARK: - Properties

    public var dashboard: HubDashboard?
    public var snapshots: [DomainSnapshot] = []
    public var briefing: DailyBriefing?
    public var isLoading = false
    public var error: PapaHubError?
    public var morningScore: Int = 0
    public var stepsCount: Int = 0
    public var sleepHours: Double = 0.0
    public var streak: Int = 0

    private let dataService: HubDataServiceProtocol
    private let scoreCalculator: ScoreCalculatorProtocol
    private let aggregator: DomainAggregatorProtocol

    // MARK: - Init

    public init(
        dataService: HubDataServiceProtocol,
        scoreCalculator: ScoreCalculatorProtocol,
        aggregator: DomainAggregatorProtocol
    ) {
        self.dataService = dataService
        self.scoreCalculator = scoreCalculator
        self.aggregator = aggregator
    }

    // MARK: - Methods

    public func loadDashboard() async {
        isLoading = true
        error = nil
        do {
            let today = Date()
            dashboard = try await dataService.fetchDashboard(for: today)
            if let dash = dashboard {
                morningScore = dash.morningScore
                stepsCount = dash.stepsCount
                sleepHours = dash.sleepHours
            }
            snapshots = try await aggregator.aggregateSnapshots(for: today)
            let recentDashboards = try await dataService.fetchDashboards(
                from: Calendar.current.date(byAdding: .day, value: -30, to: today)!,
                to: today
            )
            streak = scoreCalculator.calculateStreak(dashboards: recentDashboards)
        } catch let e as PapaHubError {
            error = e
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }

    public func refreshData() async {
        await loadDashboard()
        await loadBriefing()
    }

    public func loadBriefing() async {
        do {
            briefing = try await dataService.fetchBriefing(for: Date())
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
    }
}
