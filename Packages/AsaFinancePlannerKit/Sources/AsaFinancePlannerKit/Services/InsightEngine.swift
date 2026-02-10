import Foundation

// MARK: - InsightEngine

/// 金融インサイト生成エンジン
///
/// ルールベースで以下のインサイトを生成:
/// 1. 緊急資金不足警告（現金系資産 < 生活費6ヶ月分）
/// 2. 配分偏り検出（乖離5%以上）
/// 3. ゴール未達リスク（進捗遅れ）
/// 4. 積立増額提案
/// 5. マイルストーン達成（50%/75%/100%到達）
/// 6. 総資産成長通知
public struct InsightEngine: InsightGenerating {
    private let goalAnalyzer: GoalAnalyzing
    private let allocationOptimizer: AllocationOptimizing

    public init(
        goalAnalyzer: GoalAnalyzing = GoalFeasibilityAnalyzer(),
        allocationOptimizer: AllocationOptimizing = AllocationOptimizer()
    ) {
        self.goalAnalyzer = goalAnalyzer
        self.allocationOptimizer = allocationOptimizer
    }

    // MARK: - InsightGenerating

    public func generateInsights(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []

        // 1. 緊急資金不足警告
        insights.append(contentsOf: checkEmergencyFund(plan: plan, settings: settings))

        // 2. 配分偏り検出
        insights.append(contentsOf: checkAllocationDeviation(plan: plan, settings: settings))

        // 3. ゴール未達リスク
        insights.append(contentsOf: checkGoalProgress(plan: plan, settings: settings))

        // 4. 積立増額提案
        insights.append(contentsOf: suggestContributionIncrease(plan: plan))

        // 5. マイルストーン達成
        insights.append(contentsOf: checkMilestones(plan: plan))

        // 6. 総資産成長通知
        insights.append(contentsOf: checkAssetGrowth(plan: plan))

        return insights.sorted { $0.priority > $1.priority }
    }

    // MARK: - Private Rules

    /// 緊急資金不足警告（現金系資産 < 生活費6ヶ月分）
    private func checkEmergencyFund(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight] {
        let cashAssets = plan.assets
            .filter { $0.assetClass == .cash }
            .reduce(Decimal.zero) { $0 + $1.currentValue }

        let sixMonthExpense = settings.monthlyLivingExpense * Decimal(6)

        guard cashAssets < sixMonthExpense else { return [] }

        let shortfall = sixMonthExpense - cashAssets
        let shortfallStr = NSDecimalNumber(decimal: shortfall).intValue

        return [FinancialInsight(
            type: .warning,
            priority: .critical,
            title: "緊急資金が不足しています",
            message: "現金・預金が生活費6ヶ月分を下回っています。あと\(shortfallStr)円の確保を推奨します",
            iconName: "exclamationmark.triangle.fill"
        )]
    }

    /// 配分偏り検出
    private func checkAllocationDeviation(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight] {
        guard !plan.assets.isEmpty else { return [] }

        let currentAllocation = allocationOptimizer.calculateCurrentAllocation(assets: plan.assets)
        let targetAllocation = allocationOptimizer.suggestTargetAllocation(
            age: settings.currentAge,
            riskTolerance: .moderate
        )

        let suggestions = allocationOptimizer.generateRebalanceSuggestions(
            current: currentAllocation,
            target: targetAllocation
        )

        guard !suggestions.isEmpty else { return [] }

        let deviatedClasses = suggestions.map { $0.assetClass.displayName }.joined(separator: "、")

        return [FinancialInsight(
            type: .suggestion,
            priority: .medium,
            title: "資産配分の見直しを検討してください",
            message: "\(deviatedClasses)で目標配分との乖離が検出されました。リバランスを検討してください",
            iconName: "chart.pie.fill"
        )]
    }

    /// ゴール未達リスク
    private func checkGoalProgress(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []

        for goal in plan.goals where !goal.isCompleted {
            // 目標期日までの進捗が想定ペースを下回っているか
            let totalMonths = monthsBetween(from: goal.createdAt, to: goal.targetDate)
            let elapsedMonths = monthsBetween(from: goal.createdAt, to: Date())

            guard totalMonths > 0, elapsedMonths > 0 else { continue }

            let expectedProgress = Double(elapsedMonths) / Double(totalMonths)
            let actualProgress = goal.progressPercentage

            if actualProgress < expectedProgress * 0.7 {
                insights.append(FinancialInsight(
                    type: .warning,
                    priority: .high,
                    title: "\(goal.name)の進捗が遅れています",
                    message: "目標達成率\(String(format: "%.0f", actualProgress * 100))%（期待値: \(String(format: "%.0f", expectedProgress * 100))%）。積立額の見直しを検討してください",
                    iconName: "exclamationmark.circle.fill"
                ))
            }
        }

        return insights
    }

    /// 積立増額提案
    private func suggestContributionIncrease(
        plan: FinancialPlan
    ) -> [FinancialInsight] {
        let activeContributions = plan.contributions.filter(\.isActive)
        guard !activeContributions.isEmpty else {
            return [FinancialInsight(
                type: .suggestion,
                priority: .medium,
                title: "積立を始めましょう",
                message: "定期積立を設定すると、資産形成の効果が大幅に向上します",
                iconName: "plus.circle.fill"
            )]
        }
        return []
    }

    /// マイルストーン達成
    private func checkMilestones(
        plan: FinancialPlan
    ) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []

        for goal in plan.goals {
            let progress = goal.progressPercentage
            let milestones: [(Double, String)] = [
                (1.0, "達成"),
                (0.75, "75%"),
                (0.50, "50%"),
            ]

            for (threshold, label) in milestones {
                if progress >= threshold {
                    insights.append(FinancialInsight(
                        type: .achievement,
                        priority: .low,
                        title: "\(goal.name)が\(label)に到達しました",
                        message: "素晴らしい進捗です！引き続き頑張りましょう",
                        iconName: "star.fill"
                    ))
                    break // 最高のマイルストーンのみ通知
                }
            }
        }

        return insights
    }

    /// 総資産成長通知
    private func checkAssetGrowth(
        plan: FinancialPlan
    ) -> [FinancialInsight] {
        let totalAssets = plan.totalAssetValue
        guard totalAssets > .zero else { return [] }

        let totalStr = NSDecimalNumber(decimal: totalAssets).intValue
        let formatted = formatCurrency(totalStr)

        return [FinancialInsight(
            type: .info,
            priority: .low,
            title: "総資産状況",
            message: "現在の総資産額は\(formatted)です",
            iconName: "chart.line.uptrend.xyaxis"
        )]
    }

    // MARK: - Helpers

    private func monthsBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return max(components.month ?? 0, 0)
    }

    private func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "円"
    }
}
