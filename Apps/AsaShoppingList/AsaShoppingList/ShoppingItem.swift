import Foundation

struct ShoppingItem: Identifiable {
    let id = UUID()
    var name: String
    var isCompleted: Bool
}
