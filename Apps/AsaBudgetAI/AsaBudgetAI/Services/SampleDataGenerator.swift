import Foundation

// MARK: - SampleDataGenerator

/// デモ用サンプルデータを生成するサービス
/// 3ヶ月分のリアルな家計データを一括投入し、ダッシュボード・分析・AI機能のデモ体験を向上させる
@MainActor
final class SampleDataGenerator {

    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Public Methods

    /// サンプルデータを一括投入する
    func insertSampleData() {
        let categories = dataService.fetchCategories()
        guard !categories.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        // カテゴリを名前で引けるようにする
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })

        // 3ヶ月分の予算を作成
        let budgets = createBudgets(calendar: calendar, now: now)

        // 3ヶ月分の取引データを生成
        for monthOffset in 0..<3 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) else {
                continue
            }

            let budget = budgets[monthOffset]

            // 収入データ
            insertIncome(startOfMonth: startOfMonth, calendar: calendar, budget: budget)

            // 支出データ
            insertExpenses(
                startOfMonth: startOfMonth,
                calendar: calendar,
                categoryMap: categoryMap,
                budget: budget
            )
        }

        // 異常データ（AI分析デモ用）
        insertAnomalyTransactions(
            now: now,
            calendar: calendar,
            categoryMap: categoryMap,
            budget: budgets[0]
        )
    }

    // MARK: - Budget Generation

    private func createBudgets(calendar: Calendar, now: Date) -> [Budget] {
        var budgets: [Budget] = []

        for monthOffset in 0..<3 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                continue
            }

            let budget = Budget(
                name: "月次予算",
                totalAmount: 200_000,
                period: .monthly,
                startDate: startOfMonth,
                endDate: endOfMonth
            )
            budget.isActive = (monthOffset == 0)
            dataService.addBudget(budget)
            budgets.append(budget)
        }

        return budgets
    }

    // MARK: - Income Generation

    private func insertIncome(startOfMonth: Date, calendar: Calendar, budget: Budget) {
        // 給与：毎月25日
        guard let payDay = calendar.date(bySetting: .day, value: 25, of: startOfMonth) else { return }

        let salary = Transaction(
            amount: 350_000,
            title: "給与",
            date: payDay,
            type: .income,
            budget: budget
        )
        dataService.addTransaction(salary)
    }

    // MARK: - Expense Generation

    private func insertExpenses(
        startOfMonth: Date,
        calendar: Calendar,
        categoryMap: [String: Category],
        budget: Budget
    ) {
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30

        // カテゴリ別の支出テンプレート
        let templates: [(category: String, items: [(title: String, min: Double, max: Double)], count: ClosedRange<Int>)] = [
            ("食費", [
                ("スーパー", 1_500, 5_000),
                ("コンビニ", 300, 1_500),
                ("ランチ", 800, 1_500),
                ("カフェ", 400, 800),
                ("夕食外食", 2_000, 5_000),
            ], 8...10),
            ("交通費", [
                ("電車定期", 10_000, 15_000),
                ("バス", 200, 500),
                ("タクシー", 1_500, 5_000),
            ], 3...4),
            ("日用品", [
                ("ドラッグストア", 500, 3_000),
                ("100均", 500, 1_500),
                ("洗剤・日用品", 800, 2_000),
            ], 2...3),
            ("娯楽", [
                ("映画", 1_800, 2_500),
                ("本・マンガ", 500, 2_000),
                ("サブスク", 1_000, 2_000),
                ("ゲーム", 1_000, 5_000),
            ], 2...3),
            ("医療費", [
                ("病院", 1_000, 5_000),
                ("薬局", 500, 2_000),
            ], 0...1),
            ("教育", [
                ("参考書", 1_500, 3_000),
                ("オンライン講座", 5_000, 15_000),
            ], 1...2),
            ("光熱費", [
                ("電気代", 5_000, 12_000),
                ("ガス代", 3_000, 8_000),
                ("水道代", 3_000, 6_000),
            ], 3...3),
            ("通信費", [
                ("スマホ代", 3_000, 8_000),
                ("インターネット", 4_000, 6_000),
            ], 2...2),
            ("住居費", [
                ("家賃", 80_000, 100_000),
            ], 1...1),
            ("その他", [
                ("雑貨", 500, 2_000),
                ("プレゼント", 1_000, 3_000),
            ], 1...2),
        ]

        for template in templates {
            guard let category = categoryMap[template.category] else { continue }

            let count = Int.random(in: template.count)
            for _ in 0..<count {
                let item = template.items.randomElement()!
                let baseAmount = Double.random(in: item.min...item.max)
                // ±10% のランダム変動で自然な金額に
                let variation = baseAmount * Double.random(in: -0.1...0.1)
                let amount = max(100, round(baseAmount + variation))

                // 月内のランダムな日付
                let day = Int.random(in: 1...daysInMonth)
                guard let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) else { continue }

                let transaction = Transaction(
                    amount: amount,
                    title: item.title,
                    date: date,
                    type: .expense,
                    category: category,
                    budget: budget
                )
                dataService.addTransaction(transaction)
            }
        }
    }

    // MARK: - Anomaly Transaction Generation

    private func insertAnomalyTransactions(
        now: Date,
        calendar: Calendar,
        categoryMap: [String: Category],
        budget: Budget
    ) {
        let anomalies: [(title: String, amount: Double, score: Double, reasons: [String], category: String)] = [
            (
                "記念日ディナー",
                25_000,
                0.85,
                ["通常の食費平均を大幅に超過", "過去に類似支出なし"],
                "食費"
            ),
            (
                "コート購入",
                45_000,
                0.78,
                ["高額支出", "過去の日用品平均の15倍"],
                "日用品"
            ),
            (
                "コンサートチケット",
                30_000,
                0.72,
                ["娯楽カテゴリの月平均を大幅超過", "季節外の高額支出"],
                "娯楽"
            ),
        ]

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30

        for anomaly in anomalies {
            let day = Int.random(in: 1...min(daysInMonth, calendar.component(.day, from: now)))
            guard let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) else { continue }

            let transaction = Transaction(
                amount: anomaly.amount,
                title: anomaly.title,
                date: date,
                type: .expense,
                category: categoryMap[anomaly.category],
                budget: budget
            )
            transaction.markAsAnomaly(score: anomaly.score, reasons: anomaly.reasons)
            dataService.addTransaction(transaction)
        }
    }
}
