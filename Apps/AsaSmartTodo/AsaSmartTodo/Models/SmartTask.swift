import Foundation
import SwiftData
import AsaUIKit

// タスクカテゴリの定義
public enum TaskCategory: String, CaseIterable, Codable {
    case work = "仕事"
    case personal = "個人"
    case family = "家族"
    case health = "健康"
    case learning = "学習"
    case other = "その他"
}

// AI予測結果
public struct PredictionResult {
    let suggestedPriority: TaskPriority
    let confidenceScore: Double
    let reasoning: String
    let features: TaskFeatures
}

// タスク特徴量
public struct TaskFeatures: Codable {
    let titleWordCount: Int
    let descriptionComplexity: Double
    let daysUntilDue: Int?
    let createdHour: Int // 作成時刻（朝活判定用）
    let categoryImportanceScore: Double
    let historicalCompletionRate: Double?
}

@Model
public final class SmartTask {
    // MARK: - Properties

    public var id: UUID
    public var title: String
    public var taskDescription: String?

    // 優先度（ユーザー設定とAI提案）
    public var userPriorityRawValue: String
    public var aiSuggestedPriorityRawValue: String
    public var confidenceScore: Double
    public var predictionReason: String

    // カテゴリとステータス
    public var categoryRawValue: String
    public var statusRawValue: String

    // 日時情報
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?

    // 学習用メタデータ
    public var titleWordCount: Int
    public var descriptionComplexity: Double
    public var daysUntilDue: Int?
    public var createdHour: Int
    public var feedbackProvided: Bool
    public var feedbackIsPositive: Bool?

    // MARK: - Computed Properties

    public var userPriority: TaskPriority {
        get { TaskPriority(rawValue: userPriorityRawValue) ?? .medium }
        set { userPriorityRawValue = newValue.rawValue }
    }

    public var aiSuggestedPriority: TaskPriority {
        get { TaskPriority(rawValue: aiSuggestedPriorityRawValue) ?? .medium }
        set { aiSuggestedPriorityRawValue = newValue.rawValue }
    }

    public var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    public var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }

    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .done
    }

    public var priorityAccepted: Bool {
        return userPriority == aiSuggestedPriority
    }

    // MARK: - Initializer

    public init(
        title: String,
        description: String? = nil,
        category: TaskCategory = .other,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.categoryRawValue = category.rawValue
        self.dueDate = dueDate

        // デフォルト値
        self.userPriorityRawValue = TaskPriority.medium.rawValue
        self.aiSuggestedPriorityRawValue = TaskPriority.medium.rawValue
        self.confidenceScore = 0.0
        self.predictionReason = "分析中..."
        self.statusRawValue = TaskStatus.todo.rawValue

        // 日時
        self.createdAt = Date()
        self.updatedAt = Date()

        // 特徴量の初期計算
        self.titleWordCount = title.split(separator: " ").count
        self.descriptionComplexity = Double(description?.count ?? 0) / 100.0
        self.createdHour = Calendar.current.component(.hour, from: Date())

        if let dueDate = dueDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            self.daysUntilDue = days
        }

        self.feedbackProvided = false
    }

    // MARK: - Methods

    public func updatePrediction(_ result: PredictionResult) {
        self.aiSuggestedPriority = result.suggestedPriority
        self.confidenceScore = result.confidenceScore
        self.predictionReason = result.reasoning
        self.updatedAt = Date()
    }

    public func provideFeedback(accepted: Bool) {
        self.feedbackProvided = true
        self.feedbackIsPositive = accepted
        if accepted {
            self.userPriority = self.aiSuggestedPriority
        }
        self.updatedAt = Date()
    }

    public func complete() {
        self.status = .done
        self.completedAt = Date()
        self.updatedAt = Date()
    }

    public func updateDetails(
        title: String? = nil,
        description: String? = nil,
        category: TaskCategory? = nil,
        dueDate: Date? = nil
    ) {
        if let title = title {
            self.title = title
            self.titleWordCount = title.split(separator: " ").count
        }

        if let description = description {
            self.taskDescription = description
            self.descriptionComplexity = Double(description.count) / 100.0
        }

        if let category = category {
            self.category = category
        }

        if dueDate != nil {
            self.dueDate = dueDate
            if let date = dueDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                self.daysUntilDue = days
            } else {
                self.daysUntilDue = nil
            }
        }

        self.updatedAt = Date()
    }
}

// TaskStatus定義（AsaTaskKitと統一）
public enum TaskStatus: String, CaseIterable, Codable {
    case todo = "todo"
    case inProgress = "inProgress"
    case done = "done"
    case cancelled = "cancelled"

    public var displayName: String {
        switch self {
        case .todo: return "未着手"
        case .inProgress: return "進行中"
        case .done: return "完了"
        case .cancelled: return "キャンセル"
        }
    }
}