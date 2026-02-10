import Foundation
import SwiftData

// MARK: - FinancialGoal

/// 金融目標モデル
@Model
public final class FinancialGoal {
    public var id: UUID = UUID()
    public var name: String = ""
    public var categoryRawValue: String = GoalCategory.other.rawValue
    public var targetAmount: Decimal = Decimal.zero
    public var currentAmount: Decimal = Decimal.zero
    public var targetDate: Date = Date()
    public var priority: Int = 0
    public var note: String = ""
    public var createdAt: Date = Date()
    public var plan: FinancialPlan?

    public init(
        name: String,
        category: GoalCategory = .other,
        targetAmount: Decimal,
        currentAmount: Decimal = .zero,
        targetDate: Date,
        priority: Int = 0,
        note: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRawValue = category.rawValue
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.priority = priority
        self.note = note
        self.createdAt = Date()
    }

    // MARK: - Category Accessor

    /// GoalCategory への変換アクセサ（SwiftData enum保存パターン）
    public var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    // MARK: - Computed Properties

    /// 達成率（0.0〜1.0+）
    public var progressPercentage: Double {
        guard targetAmount > .zero else { return 0.0 }
        return NSDecimalNumber(decimal: currentAmount).doubleValue
            / NSDecimalNumber(decimal: targetAmount).doubleValue
    }

    /// 残り必要額
    public var remainingAmount: Decimal {
        let remaining = targetAmount - currentAmount
        return remaining > .zero ? remaining : .zero
    }

    /// 残り月数
    public var remainingMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: targetDate)
        return max(components.month ?? 0, 0)
    }

    /// 目標達成に必要な月額積立額
    public var requiredMonthlyContribution: Decimal {
        let months = remainingMonths
        guard months > 0, remainingAmount > .zero else { return .zero }
        return remainingAmount / Decimal(months)
    }

    /// 目標達成済みかどうか
    public var isCompleted: Bool {
        currentAmount >= targetAmount
    }
}
