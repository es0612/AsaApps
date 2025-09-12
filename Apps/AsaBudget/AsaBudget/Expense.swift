import Foundation

struct Expense: Codable, Identifiable, Sendable {
    let id: UUID
    let amount: Double
    let category: String
    let date: Date
    
    init(amount: Double, category: String, date: Date) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.date = date
    }
}
