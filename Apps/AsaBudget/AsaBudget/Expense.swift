import Foundation

struct Expense: Codable, Identifiable {
    let id = UUID()
    let amount: Double
    let category: String
    let date: Date
}
