import Foundation

// MARK: - 資産ViewModel

@MainActor
@Observable
public final class FinanceViewModel {
    // MARK: - Supporting Types

    public struct SpendingCategory: Identifiable, Sendable {
        public var id: UUID
        public var name: String
        public var amount: Double
        public var iconName: String

        public init(id: UUID = UUID(), name: String, amount: Double, iconName: String = "yensign") {
            self.id = id
            self.name = name
            self.amount = amount
            self.iconName = iconName
        }
    }

    // MARK: - Properties

    public var goalProgress: Double = 0.0
    public var monthlySpending: [SpendingCategory] = []
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadFinanceData() async {
        isLoading = true
        error = nil
        do {
            let snapshots = try await dataService.fetchSnapshots(for: Date())
            let financeSnapshot = snapshots.first { $0.domain == .finance }
            goalProgress = Double(financeSnapshot?.score ?? 0) / 100.0

            if monthlySpending.isEmpty {
                monthlySpending = [
                    SpendingCategory(name: "食費", amount: 45000, iconName: "cart.fill"),
                    SpendingCategory(name: "光熱費", amount: 15000, iconName: "bolt.fill"),
                    SpendingCategory(name: "教育費", amount: 20000, iconName: "book.fill"),
                    SpendingCategory(name: "交通費", amount: 10000, iconName: "car.fill"),
                ]
            }
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }
}
