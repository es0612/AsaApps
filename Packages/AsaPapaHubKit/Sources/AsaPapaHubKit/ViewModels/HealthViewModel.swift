import Foundation

// MARK: - 健康ViewModel

@MainActor
@Observable
public final class HealthViewModel {
    // MARK: - Properties

    public var weeklySteps: [Date: Int] = [:]
    public var weeklySleep: [Date: Double] = [:]
    public var selectedPeriod: ChartPeriod = .week
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadHealthData() async {
        isLoading = true
        error = nil
        do {
            let calendar = Calendar.current
            let today = Date()
            let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.dayCount, to: today)!
            let dashboards = try await dataService.fetchDashboards(from: startDate, to: today)

            weeklySteps = [:]
            weeklySleep = [:]
            for dashboard in dashboards {
                let day = calendar.startOfDay(for: dashboard.date)
                weeklySteps[day] = dashboard.stepsCount
                weeklySleep[day] = dashboard.sleepHours
            }
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }

    public func changePeriod(_ period: ChartPeriod) async {
        selectedPeriod = period
        await loadHealthData()
    }
}
