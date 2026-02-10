import Foundation
import Testing
@testable import AsaFinancePlannerKit

@Suite("FinancialGoal テスト")
struct FinancialGoalTests {

    @Test("目標初期化")
    func testInit() {
        let goal = FinancialGoal(
            name: "住宅購入",
            category: .housing,
            targetAmount: Decimal(30000000),
            targetDate: Date().addingTimeInterval(86400 * 365 * 10)
        )
        #expect(goal.name == "住宅購入")
        #expect(goal.category == .housing)
        #expect(goal.targetAmount == Decimal(30000000))
        #expect(goal.currentAmount == .zero)
    }

    @Test("カテゴリのrawValue変換")
    func testCategoryRawValue() {
        let goal = FinancialGoal(
            name: "老後資金",
            category: .retirement,
            targetAmount: Decimal(20000000),
            targetDate: Date()
        )
        #expect(goal.categoryRawValue == "retirement")
        #expect(goal.category == .retirement)

        goal.category = .education
        #expect(goal.categoryRawValue == "education")
    }

    @Test("達成率の計算")
    func testProgressPercentage() {
        let goal = FinancialGoal(
            name: "テスト",
            targetAmount: Decimal(1000000),
            currentAmount: Decimal(250000),
            targetDate: Date()
        )
        #expect(goal.progressPercentage == 0.25)
    }

    @Test("残り必要額の計算")
    func testRemainingAmount() {
        let goal = FinancialGoal(
            name: "テスト",
            targetAmount: Decimal(1000000),
            currentAmount: Decimal(600000),
            targetDate: Date()
        )
        #expect(goal.remainingAmount == Decimal(400000))
    }

    @Test("目標達成済みの判定")
    func testIsCompleted() {
        let goal = FinancialGoal(
            name: "達成済み",
            targetAmount: Decimal(500000),
            currentAmount: Decimal(500000),
            targetDate: Date()
        )
        #expect(goal.isCompleted == true)
        #expect(goal.remainingAmount == .zero)
    }

    @Test("超過達成の場合のremainingAmount")
    func testOverachieved() {
        let goal = FinancialGoal(
            name: "超過",
            targetAmount: Decimal(100000),
            currentAmount: Decimal(150000),
            targetDate: Date()
        )
        #expect(goal.isCompleted == true)
        #expect(goal.remainingAmount == .zero)
    }

    @Test("targetAmountがゼロの場合")
    func testZeroTarget() {
        let goal = FinancialGoal(
            name: "ゼロ",
            targetAmount: .zero,
            targetDate: Date()
        )
        #expect(goal.progressPercentage == 0.0)
        #expect(goal.requiredMonthlyContribution == .zero)
    }
}
