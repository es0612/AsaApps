import SwiftUI
import Observation

@Observable
class ShoppingListManager {
    var items: [ShoppingItem] = [
        ShoppingItem(name: "牛乳", isCompleted: false),
        ShoppingItem(name: "パン", isCompleted: false),
        ShoppingItem(name: "卵", isCompleted: false),
        ShoppingItem(name: "りんご", isCompleted: false),
        ShoppingItem(name: "シャンプー", isCompleted: false)
    ]

    func toggleCompletion(for item: ShoppingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }
}
