// AsaCoreKit統合テスト - AsaBudget
// このファイルは統合テスト用の一時的なファイルです

import Foundation
import Observation

// AsaCoreKitの模擬インポート確認
// 実際のプロジェクトでは import AsaCoreKit として統合

// ExpenseViewModel統合後の基本動作確認
@MainActor
func testExpenseViewModelIntegration() {
    print("🧪 AsaCoreKit統合テスト開始")
    
    // 1. 新しいExpenseモデルのテスト
    let expense = Expense(amount: 1000.0, category: "食費", date: Date())
    print("✅ Expense作成: \(expense.amount)円 - \(expense.category)")
    
    // 2. ViewModelの基本プロパティ確認
    let viewModel = ExpenseViewModel()
    print("✅ ExpenseViewModel初期化完了")
    print("📊 初期expenses数: \(viewModel.expenses.count)")
    print("🔑 永続化キー: \(viewModel.persistenceKey)")
    
    // 3. フォーム状態の確認
    viewModel.amount = "1500"
    viewModel.category = "交通費"
    print("✅ フォーム状態設定: \(viewModel.amount)円 - \(viewModel.category)")
    
    // 4. バリデーション機能テスト
    viewModel.validateAmount()
    if let error = viewModel.amountError {
        print("❌ バリデーションエラー: \(error)")
    } else {
        print("✅ バリデーション成功: \(viewModel.amount)")
    }
    
    print("🎉 AsaCoreKit統合テスト完了")
    print("")
    print("📋 統合による改善点:")
    print("  - UserDefaults手動実装 → PersistenceManager自動化")
    print("  - カスタムバリデーション → ValidationEngine標準化") 
    print("  - 手動CRUD処理 → CRUDOperationsClass自動化")
    print("  - エラーハンドリング → BaseViewModel統一化")
    print("  - 非同期処理 → safeAsync安全化")
}

// テスト実行
testExpenseViewModelIntegration()