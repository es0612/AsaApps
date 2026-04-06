import Foundation
import SwiftData

// MARK: - SampleDataService

/// デモ動画撮影用のサンプルデータサービス
/// アクティブプラン1件 + 資産5件 + 目標4件 + 積立2件 + シナリオ2件 + ユーザー設定を投入
@MainActor
public final class SampleDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Init

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// サンプルデータを一括投入（既存アクティブプランがあれば何もしない）
    public func loadSampleData() throws {
        // 既存プランチェック
        let planDescriptor = FetchDescriptor<FinancialPlan>(
            predicate: #Predicate { $0.isActive }
        )
        if try modelContext.fetch(planDescriptor).first != nil {
            return
        }

        // 1. メインのファイナンシャルプランを作成
        let plan = FinancialPlan(name: "山田家の資産計画", currencyCode: "JPY")
        modelContext.insert(plan)

        // 2. 資産を作成（5件、多様な資産クラス）
        let assets = createAssets()
        for asset in assets {
            asset.plan = plan
            plan.assets.append(asset)
            modelContext.insert(asset)
        }

        // 3. 金融目標を作成（4件、多様なカテゴリ）
        let goals = createGoals()
        for goal in goals {
            goal.plan = plan
            plan.goals.append(goal)
            modelContext.insert(goal)
        }

        // 4. 定期積立を作成（2件）
        let contributions = createContributions()
        for contribution in contributions {
            contribution.plan = plan
            plan.contributions.append(contribution)
            modelContext.insert(contribution)
        }

        // 5. シミュレーションシナリオを作成（2件：デフォルト + 楽観）
        let scenarios = createScenarios()
        for scenario in scenarios {
            scenario.plan = plan
            plan.scenarios.append(scenario)
            modelContext.insert(scenario)
        }

        // 6. ユーザー設定を作成（既存がなければ）
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if try modelContext.fetch(settingsDescriptor).first == nil {
            let settings = UserSettings(
                currencyCode: "JPY",
                currentAge: 38,
                retirementAge: 65,
                defaultInflationRate: Decimal(string: "0.02") ?? Decimal.zero,
                isBiometricEnabled: false,
                monthlyLivingExpense: Decimal(280000)
            )
            modelContext.insert(settings)
        }

        // 7. 一括保存
        try modelContext.save()
    }

    // MARK: - Private Helpers

    /// サンプル資産5件を生成（リアルな日本人家族の保有資産）
    private func createAssets() -> [Asset] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // 現金預金（メイン銀行口座）
            Asset(
                name: "三井住友銀行 普通預金",
                assetClass: .cash,
                currentValue: Decimal(3_500_000),
                acquisitionCost: Decimal(3_500_000),
                acquisitionDate: calendar.date(byAdding: .year, value: -5, to: now) ?? now,
                note: "生活費と緊急資金"
            ),
            // 国内株式 NISA
            Asset(
                name: "日経225連動型 NISA",
                assetClass: .domesticStock,
                currentValue: Decimal(2_800_000),
                acquisitionCost: Decimal(2_300_000),
                acquisitionDate: calendar.date(byAdding: .year, value: -3, to: now) ?? now,
                note: "つみたてNISA 長期投資"
            ),
            // 海外株式 iDeCo
            Asset(
                name: "S&P500インデックス iDeCo",
                assetClass: .internationalStock,
                currentValue: Decimal(1_800_000),
                acquisitionCost: Decimal(1_400_000),
                acquisitionDate: calendar.date(byAdding: .year, value: -4, to: now) ?? now,
                note: "iDeCo 老後資金"
            ),
            // 国内債券
            Asset(
                name: "個人向け国債 変動10年",
                assetClass: .domesticBond,
                currentValue: Decimal(1_000_000),
                acquisitionCost: Decimal(1_000_000),
                acquisitionDate: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
                note: "安定運用"
            ),
            // REIT
            Asset(
                name: "J-REIT ETF",
                assetClass: .reit,
                currentValue: Decimal(700_000),
                acquisitionCost: Decimal(600_000),
                acquisitionDate: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
                note: "不動産分散"
            ),
        ]
    }

    /// サンプル目標4件を生成
    private func createGoals() -> [FinancialGoal] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // 老後資金（最優先）
            FinancialGoal(
                name: "老後資金（27年後）",
                category: .retirement,
                targetAmount: Decimal(30_000_000),
                currentAmount: Decimal(4_600_000),
                targetDate: calendar.date(byAdding: .year, value: 27, to: now) ?? now,
                priority: 1,
                note: "65歳までに3,000万円"
            ),
            // 子供の大学資金
            FinancialGoal(
                name: "子供の大学資金",
                category: .education,
                targetAmount: Decimal(8_000_000),
                currentAmount: Decimal(2_200_000),
                targetDate: calendar.date(byAdding: .year, value: 10, to: now) ?? now,
                priority: 2,
                note: "長男の大学進学まで10年"
            ),
            // 住宅リフォーム
            FinancialGoal(
                name: "住宅リフォーム",
                category: .housing,
                targetAmount: Decimal(5_000_000),
                currentAmount: Decimal(1_500_000),
                targetDate: calendar.date(byAdding: .year, value: 5, to: now) ?? now,
                priority: 3,
                note: "キッチンと浴室のリフォーム"
            ),
            // 家族旅行
            FinancialGoal(
                name: "ハワイ家族旅行",
                category: .travel,
                targetAmount: Decimal(800_000),
                currentAmount: Decimal(350_000),
                targetDate: calendar.date(byAdding: .year, value: 2, to: now) ?? now,
                priority: 4,
                note: "10周年記念旅行"
            ),
        ]
    }

    /// サンプル積立2件を生成
    private func createContributions() -> [Contribution] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .year, value: -3, to: now) ?? now

        return [
            Contribution(
                name: "つみたてNISA",
                monthlyAmount: Decimal(33_333),
                assetClass: .domesticStock,
                isActive: true,
                startDate: startDate
            ),
            Contribution(
                name: "iDeCo 月額拠出",
                monthlyAmount: Decimal(23_000),
                assetClass: .internationalStock,
                isActive: true,
                startDate: calendar.date(byAdding: .year, value: -4, to: now) ?? now
            ),
        ]
    }

    /// サンプルシナリオ2件を生成（デフォルト + 楽観）
    private func createScenarios() -> [Scenario] {
        return [
            Scenario(
                name: "標準シナリオ",
                annualReturnRate: Decimal(string: "0.05") ?? Decimal.zero,
                inflationRate: Decimal(string: "0.02") ?? Decimal.zero,
                projectionYears: 30,
                isDefault: true
            ),
            Scenario(
                name: "楽観シナリオ",
                annualReturnRate: Decimal(string: "0.07") ?? Decimal.zero,
                inflationRate: Decimal(string: "0.02") ?? Decimal.zero,
                projectionYears: 30,
                isDefault: false
            ),
        ]
    }
}
