import Observation
import Foundation

@Observable
class ExpenseViewModel {
    var expenses: [Expense] = []
    var amount: String = ""
    var category: String = "食費"
    var date: Date = Date()
    let categories = ["食費", "娯楽", "交通費", "生活費"]
    
    func addExpense() {
        guard let amountDouble = Double(amount), amountDouble > 0 else { return }
        let newExpense = Expense(amount: amountDouble, category: category, date: date)
        expenses.append(newExpense)
        saveToUserDefaults()
        amount = ""
        date = Date()
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: "expenses")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "expenses"),
           let savedExpenses = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = savedExpenses
        }
    }
    func deleteExpense(_ expenses: [Expense]) {
        self.expenses.removeAll { expense in
            expenses.contains { $0.id == expense.id }
        }
        saveToUserDefaults()
    }
}
