import Observation
import Foundation
import AsaCoreKit

@MainActor
@Observable
class ExpenseViewModel: BaseViewModel, CRUDOperationsClass {
    typealias Model = Expense
    
    // MARK: - CRUDOperationsClass Requirements
    var items: [Expense] = []
    let persistenceKey = "expenses"
    
    // MARK: - Form Properties  
    var amount: String = ""
    var category: String = "食費"
    var date: Date = Date()
    let categories = ["食費", "娯楽", "交通費", "生活費"]
    var amountError: String? = nil
    
    // MARK: - Computed Properties
    var expenses: [Expense] {
        return items
    }
    
    // MARK: - Initialization
    override func initialize() {
        super.initialize()
        loadExpenses()
    }
    
    // MARK: - Data Management
    private func loadExpenses() {
        safeAsync {
            try await self.loadItems()
        }
    }
    
    func addExpense() {
        // Validate amount using AsaCoreKit ValidationEngine
        let validators: [any Validator<String>] = [
            ValidationEngine.required,
            ValidationEngine.number,
            ValidationEngine.positiveNumber
        ]
        
        if let error = ValidationEngine.validateString(amount, with: validators) {
            switch error {
            case .empty:
                amountError = "金額を入力してください"
            case .notANumber:
                amountError = "有効な数値を入力してください"
            case .notPositive:
                amountError = "正の金額を入力してください"
            default:
                amountError = "有効な金額を入力してください"
            }
            return
        }
        
        guard let amountDouble = Double(amount) else { return }
        
        let newExpense = Expense(amount: amountDouble, category: category, date: date)
        
        safeAsync {
            try await self.addItem(newExpense)
            self.amount = ""
            self.date = Date()
            self.amountError = nil
        }
    }
    
    func deleteExpense(_ expensesToDelete: [Expense]) {
        let idsToDelete = expensesToDelete.map { $0.id }
        safeAsync {
            try await self.deleteItems(ids: idsToDelete)
        }
    }
    
    func validateAmount() {
        // Use AsaCoreKit validation instead of custom logic
        let filtered = amount.filter { "0123456789.".contains($0) }
        amount = filtered
        
        let validators: [any Validator<String>] = [
            ValidationEngine.number,
            ValidationEngine.positiveNumber
        ]
        
        if let error = ValidationEngine.validateString(filtered, with: validators) {
            switch error {
            case .notANumber:
                amountError = filtered.isEmpty ? nil : "有効な数値を入力してください"
            case .notPositive:
                amountError = "正の金額を入力してください"
            default:
                amountError = "有効な金額を入力してください"
            }
        } else {
            amountError = nil
        }
    }
}
