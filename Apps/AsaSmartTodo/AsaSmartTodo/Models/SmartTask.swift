//
//  SmartTask.swift
//  AsaSmartTodo
//
//  AI予測機能付きタスクモデル
//  Swift Dataで永続化し、AI予測結果とユーザーフィードバックを保存
//

import Foundation
import SwiftData

@Model
final class SmartTask {
    // MARK: - 基本情報

    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - 優先度（Raw Value保存でSwift Data対応）

    /// ユーザーが設定した優先度
    var userPriorityRawValue: String

    /// AIが提案した優先度（nilの場合は未予測）
    var aiPriorityRawValue: String?

    /// 最終的に採用された優先度（ユーザー選択またはAI提案）
    var finalPriorityRawValue: String

    // MARK: - AI予測関連

    /// 信頼度スコア（0.0-1.0）
    var confidenceScore: Double

    /// 予測理由のリスト（JSON形式で保存）
    var predictionReasonsJSON: Data?

    /// ユーザーがAI予測を採用したか（nil=未判定、true=採用、false=却下）
    var wasAIPredictionAccepted: Bool?

    // MARK: - タスク属性

    /// カテゴリ（Raw Value保存）
    var categoryRawValue: String

    /// 期限（任意）
    var dueDate: Date?

    /// 完了フラグ
    var isCompleted: Bool

    /// 完了日時（任意）
    var completedAt: Date?

    // MARK: - 特徴量（学習データ用）

    /// タイトルの複雑度（0.0-1.0）
    var titleComplexity: Double

    /// 説明文の複雑度（0.0-1.0）
    var descriptionComplexity: Double

    /// 作成時刻（0-23時）朝活判定用
    var createdHour: Int

    // MARK: - Computed Properties

    /// ユーザー設定優先度
    var userPriority: PriorityLevel {
        get { PriorityLevel(rawValue: userPriorityRawValue) ?? .medium }
        set { userPriorityRawValue = newValue.rawValue }
    }

    /// AI提案優先度
    var aiPriority: PriorityLevel? {
        get {
            guard let raw = aiPriorityRawValue else { return nil }
            return PriorityLevel(rawValue: raw)
        }
        set { aiPriorityRawValue = newValue?.rawValue }
    }

    /// 最終採用優先度
    var finalPriority: PriorityLevel {
        get { PriorityLevel(rawValue: finalPriorityRawValue) ?? .medium }
        set { finalPriorityRawValue = newValue.rawValue }
    }

    /// カテゴリ
    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// 予測理由（デコード）
    var predictionReasons: [PredictionReason] {
        get {
            guard let data = predictionReasonsJSON else { return [] }
            return (try? JSONDecoder().decode([PredictionReason].self, from: data)) ?? []
        }
        set {
            predictionReasonsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 期限切れかどうか
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    /// 期限までの日数（nilは期限未設定）
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }

    // MARK: - Initializer

    init(
        title: String,
        description: String? = nil,
        category: TaskCategory = .other,
        userPriority: PriorityLevel = .medium,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.createdAt = Date()
        self.updatedAt = Date()

        // 優先度の初期化
        self.userPriorityRawValue = userPriority.rawValue
        self.aiPriorityRawValue = nil
        self.finalPriorityRawValue = userPriority.rawValue

        // AI予測の初期化
        self.confidenceScore = 0.0
        self.predictionReasonsJSON = nil
        self.wasAIPredictionAccepted = nil

        // タスク属性の初期化
        self.categoryRawValue = category.rawValue
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedAt = nil

        // 特徴量の初期化
        self.titleComplexity = 0.0
        self.descriptionComplexity = 0.0
        self.createdHour = Calendar.current.component(.hour, from: Date())
    }

    // MARK: - Methods

    /// AI予測結果を適用
    func applyPrediction(_ result: PredictionResult) {
        self.aiPriority = result.suggestedPriority
        self.confidenceScore = result.confidenceScore
        self.predictionReasons = result.reasons
        self.updatedAt = Date()
    }

    /// AI予測を採用
    func acceptAIPrediction() {
        guard let aiPriority = aiPriority else { return }
        self.finalPriority = aiPriority
        self.wasAIPredictionAccepted = true
        self.updatedAt = Date()
    }

    /// AI予測を却下（ユーザー選択を維持）
    func rejectAIPrediction() {
        self.finalPriority = userPriority
        self.wasAIPredictionAccepted = false
        self.updatedAt = Date()
    }

    /// タスクを完了
    func complete() {
        self.isCompleted = true
        self.completedAt = Date()
        self.updatedAt = Date()
    }

    /// タスクを未完了に戻す
    func uncomplete() {
        self.isCompleted = false
        self.completedAt = nil
        self.updatedAt = Date()
    }

    /// タスク情報を更新
    func updateDetails(
        title: String? = nil,
        description: String? = nil,
        category: TaskCategory? = nil,
        userPriority: PriorityLevel? = nil,
        dueDate: Date? = nil
    ) {
        if let title = title {
            self.title = title
        }
        if let description = description {
            self.taskDescription = description
        }
        if let category = category {
            self.category = category
        }
        if let userPriority = userPriority {
            self.userPriority = userPriority
            // ユーザーが優先度を変更した場合、AI予測を再実行する必要がある
            self.wasAIPredictionAccepted = nil
        }
        if let dueDate = dueDate {
            self.dueDate = dueDate
        }
        self.updatedAt = Date()
    }
}
