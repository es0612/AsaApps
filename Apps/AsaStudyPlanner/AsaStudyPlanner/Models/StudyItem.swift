import Foundation
import SwiftData

/// 学習項目を表すSwift Dataモデル
/// AI最適化エンジンで優先度を計算し、間隔反復学習で復習タイミングを管理
@Model
final class StudyItem {
    // MARK: - Core Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var itemDescription: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Category & Difficulty (Raw Values for Swift Data)

    var categoryRawValue: String
    var difficultyRawValue: String

    // MARK: - Learning Properties

    /// 推定学習時間（分）
    var estimatedMinutes: Int

    /// 目標期限
    var targetDate: Date?

    /// 習熟度（0.0-1.0）
    /// 0.0: 未学習、1.0: 完全習得
    var masteryLevel: Double

    /// 総学習時間（分）
    var totalStudyMinutes: Int

    /// 学習セッション数
    var sessionCount: Int

    // MARK: - Spaced Repetition (SM-2)

    /// 次回復習予定日
    var nextReviewDate: Date?

    /// SM-2のEaseFactor（復習間隔係数）
    /// 初期値2.5、最小1.3
    var easeFactor: Double

    /// 連続正解回数（SM-2の反復回数）
    var repetitionCount: Int

    /// 前回の復習間隔（日数）
    var lastIntervalDays: Int

    // MARK: - AI Optimization

    /// AI計算による優先度スコア（0.0-1.0）
    var aiPriorityScore: Double

    /// AI予測の信頼度
    var aiConfidenceScore: Double

    /// AI予測理由（JSON）
    var aiReasonsJSON: Data?

    /// 前提知識となる学習項目のID
    var prerequisiteItemIds: [UUID]

    // MARK: - Status

    var isArchived: Bool
    var isCompleted: Bool
    var completedAt: Date?

    // MARK: - Computed Properties

    var category: StudyCategory {
        get { StudyCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var difficulty: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficultyRawValue) ?? .medium }
        set { difficultyRawValue = newValue.rawValue }
    }

    var aiReasons: [String] {
        get {
            guard let data = aiReasonsJSON else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            aiReasonsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 期限までの日数（nilは期限なし、負は期限切れ）
    var daysUntilTarget: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: targetDate))
        return components.day
    }

    /// 期限切れかどうか
    var isOverdue: Bool {
        guard let days = daysUntilTarget else { return false }
        return days < 0
    }

    /// 復習が必要かどうか
    var needsReview: Bool {
        guard let nextReview = nextReviewDate else { return false }
        return nextReview <= Date()
    }

    /// 習熟レベルのラベル
    var masteryLabel: String {
        switch masteryLevel {
        case 0..<0.2: return "初学者"
        case 0.2..<0.4: return "入門"
        case 0.4..<0.6: return "中級"
        case 0.6..<0.8: return "上級"
        case 0.8...1.0: return "マスター"
        default: return "未定義"
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        category: StudyCategory = .other,
        difficulty: DifficultyLevel = .medium,
        estimatedMinutes: Int = 30,
        targetDate: Date? = nil,
        masteryLevel: Double = 0.0,
        prerequisiteItemIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.itemDescription = description
        self.categoryRawValue = category.rawValue
        self.difficultyRawValue = difficulty.rawValue
        self.estimatedMinutes = estimatedMinutes
        self.targetDate = targetDate
        self.masteryLevel = masteryLevel
        self.prerequisiteItemIds = prerequisiteItemIds

        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalStudyMinutes = 0
        self.sessionCount = 0

        // SM-2初期値
        self.easeFactor = 2.5
        self.repetitionCount = 0
        self.lastIntervalDays = 0
        self.nextReviewDate = nil

        // AI初期値
        self.aiPriorityScore = 0.5
        self.aiConfidenceScore = 0.0
        self.aiReasonsJSON = nil

        // Status初期値
        self.isArchived = false
        self.isCompleted = false
        self.completedAt = nil
    }

    // MARK: - Methods

    /// 学習セッション完了時の更新
    func recordSession(durationMinutes: Int, quality: Int) {
        totalStudyMinutes += durationMinutes
        sessionCount += 1
        updatedAt = Date()

        // 習熟度更新（セッション時間と品質に基づく）
        let qualityFactor = Double(quality) / 5.0
        let sessionContribution = min(Double(durationMinutes) / Double(estimatedMinutes), 1.0) * 0.1
        masteryLevel = min(masteryLevel + sessionContribution * qualityFactor, 1.0)
    }

    /// AI予測結果を適用
    func applyAIPrediction(score: Double, confidence: Double, reasons: [String]) {
        aiPriorityScore = score
        aiConfidenceScore = confidence
        aiReasons = reasons
        updatedAt = Date()
    }

    /// 学習完了としてマーク
    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
        masteryLevel = 1.0
        updatedAt = Date()
    }

    /// アーカイブ
    func archive() {
        isArchived = true
        updatedAt = Date()
    }
}
