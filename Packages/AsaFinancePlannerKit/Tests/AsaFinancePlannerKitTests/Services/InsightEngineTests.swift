import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - InsightEngineTests

@Suite("InsightEngine テスト")
struct InsightEngineTests {
    let engine = InsightEngine()

    // MARK: - Helpers

    private func makeSettings(
        monthlyLivingExpense: Decimal = Decimal(250000),
        currentAge: Int = 35
    ) -> UserSettings {
        UserSettings(
            currentAge: currentAge,
            monthlyLivingExpense: monthlyLivingExpense
        )
    }

    private func makePlan(
        assets: [Asset] = [],
        goals: [FinancialGoal] = [],
        contributions: [Contribution] = []
    ) -> FinancialPlan {
        let plan = FinancialPlan(name: "テストプラン")
        for asset in assets {
            plan.assets.append(asset)
        }
        for goal in goals {
            plan.goals.append(goal)
        }
        for contribution in contributions {
            plan.contributions.append(contribution)
        }
        return plan
    }

    // MARK: - Tests

    @Test("緊急資金不足検出")
    func testEmergencyFundWarning() {
        let plan = makePlan(
            assets: [
                Asset(name: "現金", assetClass: .cash, currentValue: Decimal(500000)),
                Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(5_000_000)),
            ]
        )
        let settings = makeSettings(monthlyLivingExpense: Decimal(250000))
        // 必要: 250,000 × 6 = 1,500,000、実際: 500,000 → 不足

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let emergencyWarning = insights.first {
            $0.type == .warning && $0.priority == .critical
        }
        #expect(emergencyWarning != nil)
        #expect(emergencyWarning?.title.contains("緊急資金") == true)
    }

    @Test("緊急資金が十分な場合は警告なし")
    func testNoEmergencyFundWarning() {
        let plan = makePlan(
            assets: [
                Asset(name: "現金", assetClass: .cash, currentValue: Decimal(2_000_000)),
            ]
        )
        let settings = makeSettings(monthlyLivingExpense: Decimal(250000))
        // 必要: 1,500,000、実際: 2,000,000 → 十分

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let emergencyWarning = insights.first {
            $0.type == .warning && $0.priority == .critical
        }
        #expect(emergencyWarning == nil)
    }

    @Test("ゴール達成マイルストーン検出（50%到達）")
    func testGoalMilestone50Percent() {
        let goal = FinancialGoal(
            name: "旅行資金",
            targetAmount: Decimal(1_000_000),
            currentAmount: Decimal(500000),
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        )

        let plan = makePlan(goals: [goal])
        let settings = makeSettings()

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let milestone = insights.first {
            $0.type == .achievement && $0.title.contains("旅行資金")
        }
        #expect(milestone != nil)
        #expect(milestone?.title.contains("50%") == true)
    }

    @Test("ゴール達成マイルストーン検出（100%到達）")
    func testGoalMilestone100Percent() {
        let goal = FinancialGoal(
            name: "貯金目標",
            targetAmount: Decimal(1_000_000),
            currentAmount: Decimal(1_000_000),
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        )

        let plan = makePlan(goals: [goal])
        let settings = makeSettings()

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let milestone = insights.first {
            $0.type == .achievement && $0.title.contains("貯金目標")
        }
        #expect(milestone != nil)
        #expect(milestone?.title.contains("達成") == true)
    }

    @Test("積立なしの場合は積立開始提案")
    func testContributionSuggestion() {
        let plan = makePlan(
            assets: [Asset(name: "現金", assetClass: .cash, currentValue: Decimal(3_000_000))]
        )
        let settings = makeSettings()

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let suggestion = insights.first {
            $0.type == .suggestion && $0.title.contains("積立")
        }
        #expect(suggestion != nil)
    }

    @Test("配分偏り検出（資産がある場合）")
    func testAllocationDeviationDetection() {
        // 全て現金に偏った配分
        let plan = makePlan(
            assets: [
                Asset(name: "現金", assetClass: .cash, currentValue: Decimal(10_000_000)),
            ]
        )
        let settings = makeSettings()

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let allocationSuggestion = insights.first {
            $0.type == .suggestion && $0.title.contains("資産配分")
        }
        #expect(allocationSuggestion != nil)
    }

    @Test("総資産成長通知")
    func testAssetGrowthNotification() {
        let plan = makePlan(
            assets: [
                Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(5_000_000)),
            ]
        )
        let settings = makeSettings()

        let insights = engine.generateInsights(plan: plan, settings: settings)

        let assetInfo = insights.first { $0.type == .info }
        #expect(assetInfo != nil)
        #expect(assetInfo?.title.contains("総資産") == true)
    }

    @Test("インサイトは優先度順にソートされる")
    func testInsightsSortedByPriority() {
        let plan = makePlan(
            assets: [
                Asset(name: "現金", assetClass: .cash, currentValue: Decimal(100000)),
                Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(5_000_000)),
            ],
            goals: [
                FinancialGoal(
                    name: "テスト目標",
                    targetAmount: Decimal(1_000_000),
                    currentAmount: Decimal(500000),
                    targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
                ),
            ]
        )
        let settings = makeSettings(monthlyLivingExpense: Decimal(250000))

        let insights = engine.generateInsights(plan: plan, settings: settings)

        // 優先度が降順であることを確認
        for i in 1..<insights.count {
            #expect(insights[i - 1].priority >= insights[i].priority)
        }
    }
}
