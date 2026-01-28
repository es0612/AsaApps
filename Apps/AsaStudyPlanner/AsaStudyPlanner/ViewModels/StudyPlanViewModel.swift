import Foundation
import SwiftUI
import SwiftData

/// 学習計画のViewModel
/// AI最適化エンジンと間隔反復学習を統合して学習計画を管理
@MainActor
@Observable
final class StudyPlanViewModel {

    // MARK: - Dependencies

    private let dataService: DataService
    private let optimizer: StudyOptimizer
    private let spacedRepetitionEngine: SpacedRepetitionEngine

    // MARK: - State

    private(set) var studyItems: [StudyItem] = []
    private(set) var todaysPlan: StudyPlan?
    private(set) var todaysAnalytics: LearningAnalytics?
    private(set) var userProfile: UserLearningProfile?

    private(set) var optimizationResult: OptimizationResult?
    private(set) var reviewStats: ReviewStatistics?

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - UI State

    var showingAddItem = false
    var selectedItem: StudyItem?
    var showingOptimizationDetails = false

    // MARK: - Computed Properties

    var activeItems: [StudyItem] {
        studyItems.filter { !$0.isArchived && !$0.isCompleted }
    }

    var completedItems: [StudyItem] {
        studyItems.filter { $0.isCompleted && !$0.isArchived }
    }

    var itemsNeedingReview: [StudyItem] {
        spacedRepetitionEngine.filterItemsNeedingReview(activeItems)
    }

    var urgentItems: [StudyItem] {
        activeItems.filter { ($0.daysUntilTarget ?? 100) <= 3 }
    }

    var topPriorityItems: [StudyItem] {
        guard let result = optimizationResult else {
            return Array(activeItems.prefix(5))
        }

        return result.orderedItemIds.prefix(5).compactMap { id in
            activeItems.first { $0.id == id }
        }
    }

    var morningScore: Int {
        todaysAnalytics?.morningScore ?? 0
    }

    var todayTotalMinutes: Int {
        todaysAnalytics?.totalMinutes ?? 0
    }

    var dailyGoalMinutes: Int {
        userProfile?.dailyGoalMinutes ?? 120
    }

    var dailyProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(Double(todayTotalMinutes) / Double(dailyGoalMinutes), 1.0)
    }

    // MARK: - Initializer

    init(
        dataService: DataService,
        optimizer: StudyOptimizer = StudyOptimizer(),
        spacedRepetitionEngine: SpacedRepetitionEngine = SpacedRepetitionEngine()
    ) {
        self.dataService = dataService
        self.optimizer = optimizer
        self.spacedRepetitionEngine = spacedRepetitionEngine
    }

    /// メインアクターコンテキストで使用するデフォルト初期化
    init() {
        self.dataService = DataService()
        self.optimizer = StudyOptimizer()
        self.spacedRepetitionEngine = SpacedRepetitionEngine()
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        errorMessage = nil

        // データ読み込み
        studyItems = dataService.fetchStudyItems(includeArchived: false, includeCompleted: true)
        todaysPlan = dataService.fetchOrCreateTodaysPlan(
            morningGoalMinutes: userProfile?.morningGoalMinutes ?? 60
        )
        todaysAnalytics = dataService.fetchOrCreateAnalytics(for: Date())
        userProfile = dataService.fetchOrCreateProfile()

        // AI最適化実行
        runOptimization()

        // 復習統計計算
        reviewStats = spacedRepetitionEngine.calculateReviewStats(for: activeItems)

        isLoading = false
    }

    func refresh() {
        loadData()
    }

    // MARK: - AI Optimization

    func runOptimization() {
        guard !activeItems.isEmpty else {
            optimizationResult = .empty
            return
        }

        // ユーザー設定の重みを使用
        if let profile = userProfile, profile.aiOptimizationEnabled {
            optimizer.updateWeights(profile.effectiveWeights)
        }

        // 最適化実行
        optimizationResult = optimizer.optimizeStudyOrder(items: activeItems)

        // 結果を各アイテムに適用
        if let result = optimizationResult {
            optimizer.applyOptimizationToItems(activeItems, result: result)
            dataService.save()
        }
    }

    /// AI提案を採用
    func acceptAIRecommendation(for item: StudyItem) {
        todaysAnalytics?.recordAIFeedback(accepted: true)
        dataService.save()
    }

    /// AI提案を却下
    func rejectAIRecommendation(for item: StudyItem) {
        todaysAnalytics?.recordAIFeedback(accepted: false)
        dataService.save()
    }

    // MARK: - CRUD Operations

    func createStudyItem(
        title: String,
        description: String? = nil,
        category: StudyCategory,
        difficulty: DifficultyLevel,
        estimatedMinutes: Int,
        targetDate: Date?
    ) {
        let item = dataService.createStudyItem(
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedMinutes: estimatedMinutes,
            targetDate: targetDate
        )

        // AI優先度を計算
        let result = optimizer.calculatePriority(for: item)
        item.applyAIPrediction(
            score: result.totalScore,
            confidence: 0.7,
            reasons: result.reasons
        )
        dataService.save()

        // リストを更新
        loadData()
    }

    func updateStudyItem(_ item: StudyItem) {
        item.updatedAt = Date()

        // AI優先度を再計算
        let result = optimizer.calculatePriority(for: item)
        item.applyAIPrediction(
            score: result.totalScore,
            confidence: 0.7,
            reasons: result.reasons
        )

        dataService.save()
        runOptimization()
    }

    func deleteStudyItem(_ item: StudyItem) {
        dataService.deleteStudyItem(item)
        loadData()
    }

    func archiveStudyItem(_ item: StudyItem) {
        item.archive()
        dataService.save()
        loadData()
    }

    func markItemAsCompleted(_ item: StudyItem) {
        item.markAsCompleted()
        todaysAnalytics?.completedItems += 1
        dataService.save()
        loadData()
    }

    // MARK: - Session Management

    func startSession(for item: StudyItem, plannedMinutes: Int) -> StudySession {
        let session = dataService.createStudySession(
            studyItemId: item.id,
            plannedMinutes: plannedMinutes
        )
        return session
    }

    func completeSession(
        _ session: StudySession,
        item: StudyItem,
        focusLevel: Int,
        comprehensionLevel: Int,
        notes: String?
    ) {
        // セッション完了
        session.complete(focusLevel: focusLevel, comprehensionLevel: comprehensionLevel, notes: notes)

        // アイテムの統計更新
        item.recordSession(durationMinutes: session.actualMinutes, quality: session.qualityScore)

        // SM-2による復習スケジュール更新
        spacedRepetitionEngine.updateItemAfterSession(item: item, session: session)

        // 分析データ更新
        todaysAnalytics?.recordSession(session, category: item.category)

        // 計画データ更新
        todaysPlan?.markItemCompleted(item.id, minutes: session.actualMinutes, isMorning: session.isMorningSession)

        dataService.save()
        loadData()
    }

    func interruptSession(_ session: StudySession) {
        session.interrupt()
        dataService.save()
    }

    // MARK: - Review Management

    func getReviewPriorityItems(limit: Int = 5) -> [StudyItem] {
        optimizer.getReviewPriorityItems(activeItems, limit: limit)
    }

    func getMorningOptimalItems(limit: Int = 3) -> [StudyItem] {
        optimizer.getOptimalMorningItems(activeItems, limit: limit)
    }

    func getDeadlinePriorityItems(limit: Int = 5) -> [StudyItem] {
        optimizer.getDeadlinePriorityItems(activeItems, limit: limit)
    }

    // MARK: - Analytics

    func getWeeklyAnalytics() -> [LearningAnalytics] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        return dataService.fetchAnalytics(from: weekAgo, to: today)
    }

    func getMonthlyAnalytics() -> [LearningAnalytics] {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!

        return dataService.fetchAnalytics(from: monthAgo, to: today)
    }

    // MARK: - Settings

    func updateProfile(_ profile: UserLearningProfile) {
        profile.update()
        dataService.save()

        // 最適化重みを更新
        if profile.aiOptimizationEnabled {
            optimizer.updateWeights(profile.effectiveWeights)
            runOptimization()
        }
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Helper

extension StudyPlanViewModel {
    static func preview() -> StudyPlanViewModel {
        let vm = StudyPlanViewModel(dataService: DataService(inMemory: true))

        // サンプルデータを追加
        vm.createStudyItem(
            title: "Swift並行処理",
            description: "async/await、Actor、Sendableの学習",
            category: .programming,
            difficulty: .hard,
            estimatedMinutes: 60,
            targetDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )

        vm.createStudyItem(
            title: "英語リーディング",
            description: "技術文書の読解練習",
            category: .language,
            difficulty: .medium,
            estimatedMinutes: 30,
            targetDate: nil
        )

        return vm
    }
}
