import Foundation
import SwiftData

@MainActor
@Observable
final class OrderViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext?

    private(set) var orders: [Order] = []
    private(set) var isLoading = false

    // MARK: - Initialization

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadOrders()
    }

    // MARK: - Methods

    func loadOrders() {
        guard let modelContext else { return }

        isLoading = true

        do {
            let descriptor = FetchDescriptor<Order>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            orders = try modelContext.fetch(descriptor)
        } catch {
            orders = []
        }

        isLoading = false
    }

    func order(by id: UUID) -> Order? {
        orders.first { $0.id == id }
    }

    func deleteOrder(_ order: Order) {
        guard let modelContext else { return }

        modelContext.delete(order)

        do {
            try modelContext.save()
            loadOrders()
        } catch {
            // エラー処理
        }
    }
}
