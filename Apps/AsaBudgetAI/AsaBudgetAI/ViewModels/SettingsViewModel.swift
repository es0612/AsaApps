import Foundation

// MARK: - SettingsViewModel

/// 設定画面のViewModel
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Properties

    var settings: UserSettings
    var categories: [Category] = []
    var isLoading = false
    var isSaving = false
    var showWeightsNormalizationAlert = false

    // MARK: - Dependencies

    private let dataService: DataService
    private let notificationService: NotificationService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        self.notificationService = NotificationService.shared
        self.settings = dataService.fetchUserSettings()
        self.categories = dataService.fetchCategories()
    }

    // MARK: - Settings Management

    func loadSettings() {
        isLoading = true
        settings = dataService.fetchUserSettings()
        categories = dataService.fetchCategories()
        isLoading = false
    }

    func saveSettings() {
        isSaving = true

        // 重みを正規化
        if !settings.isWeightsValid {
            settings.normalizeWeights()
        }

        dataService.updateUserSettings(settings)

        // 通知設定を更新
        updateNotificationSettings()

        isSaving = false

        // 重み変更通知を送信
        NotificationCenter.default.post(
            name: .aiWeightsDidChange,
            object: settings.analysisWeights
        )
    }

    // MARK: - AI Weights

    func resetWeightsToDefault() {
        settings.resetWeightsToDefault()
        saveSettings()
    }

    func normalizeWeights() {
        settings.normalizeWeights()
        showWeightsNormalizationAlert = true
    }

    // MARK: - Notification Settings

    private func updateNotificationSettings() {
        if settings.dailyReportEnabled {
            notificationService.scheduleDailyReport(hour: settings.dailyReportHour)
        } else {
            notificationService.cancelDailyReport()
        }
    }

    func requestNotificationPermission() async -> Bool {
        await notificationService.requestAuthorization()
    }

    func checkNotificationStatus() async -> Bool {
        let status = await notificationService.checkAuthorizationStatus()
        return status == .authorized
    }

    // MARK: - Category Management

    func addCategory(name: String, iconName: String, colorHex: String) {
        let category = Category(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            sortOrder: categories.count
        )
        dataService.addCategory(category)
        categories = dataService.fetchCategories()
    }

    func deleteCategory(_ category: Category) {
        guard !category.isDefault else { return }
        dataService.deleteCategory(category)
        categories = dataService.fetchCategories()
    }

    func reorderCategories(_ categories: [Category]) {
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }
        self.categories = categories
    }

    // MARK: - Data Management

    func insertSampleData() {
        isLoading = true
        let generator = SampleDataGenerator(dataService: dataService)
        generator.insertSampleData()
        categories = dataService.fetchCategories()
        isLoading = false
    }

    func exportData() -> Data? {
        let transactions = dataService.fetchTransactions()

        let exportData = ExportData(
            transactions: transactions.map { TransactionExport(from: $0) },
            exportedAt: Date(),
            version: "1.0"
        )

        return try? JSONEncoder().encode(exportData)
    }

    func clearAllData() {
        // 全取引を削除
        let transactions = dataService.fetchTransactions()
        for transaction in transactions {
            dataService.deleteTransaction(transaction)
        }

        // 予算を削除
        let budgets = dataService.fetchBudgets()
        for budget in budgets {
            dataService.deleteBudget(budget)
        }

        // 設定をリセット
        settings.resetWeightsToDefault()
        saveSettings()
    }

    // MARK: - Computed Properties

    var isWeightsValid: Bool {
        settings.isWeightsValid
    }

    var totalWeightsPercentage: Int {
        Int(settings.totalWeights * 100)
    }

    var customCategories: [Category] {
        categories.filter { !$0.isDefault }
    }

    var defaultCategories: [Category] {
        categories.filter { $0.isDefault }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let aiWeightsDidChange = Notification.Name("aiWeightsDidChange")
}

// MARK: - Export Data

private struct ExportData: Codable {
    let transactions: [TransactionExport]
    let exportedAt: Date
    let version: String
}

private struct TransactionExport: Codable {
    let id: UUID
    let amount: Double
    let title: String
    let note: String?
    let date: Date
    let type: String
    let categoryName: String?
    let isAnomaly: Bool

    init(from transaction: Transaction) {
        self.id = transaction.id
        self.amount = transaction.amount
        self.title = transaction.title
        self.note = transaction.note
        self.date = transaction.date
        self.type = transaction.type.rawValue
        self.categoryName = transaction.category?.name
        self.isAnomaly = transaction.isAnomaly
    }
}

// MARK: - Icon Options

extension SettingsViewModel {
    static let availableIcons = [
        "fork.knife",
        "car.fill",
        "cart.fill",
        "gamecontroller.fill",
        "cross.case.fill",
        "book.fill",
        "bolt.fill",
        "antenna.radiowaves.left.and.right",
        "house.fill",
        "gift.fill",
        "airplane",
        "tshirt.fill",
        "heart.fill",
        "briefcase.fill",
        "bag.fill",
        "creditcard.fill",
        "banknote.fill",
        "doc.fill",
        "phone.fill",
        "tv.fill",
        "music.note",
        "film.fill",
        "camera.fill",
        "paintbrush.fill",
        "hammer.fill",
        "wrench.fill",
        "leaf.fill",
        "drop.fill",
        "flame.fill",
        "snowflake"
    ]

    static let availableColors = [
        "#FF6B6B",  // 赤
        "#4ECDC4",  // ティール
        "#45B7D1",  // 水色
        "#96CEB4",  // ミント
        "#FFEAA7",  // 黄色
        "#DDA0DD",  // 紫
        "#FFB347",  // オレンジ
        "#87CEEB",  // スカイブルー
        "#C68C53",  // ブラウン
        "#98D8C8",  // 薄緑
        "#F7DC6F",  // ゴールド
        "#BB8FCE",  // ラベンダー
        "#85C1E9",  // ライトブルー
        "#F8B500",  // アンバー
        "#82E0AA"   // グリーン
    ]
}
