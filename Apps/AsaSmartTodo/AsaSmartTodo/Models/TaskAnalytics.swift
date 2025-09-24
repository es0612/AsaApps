import Foundation
import SwiftData

@Model
public final class TaskAnalytics {
    // MARK: - Properties

    public var id: UUID
    public var date: Date

    // 生産性メトリクス
    public var totalTasksCreated: Int
    public var totalTasksCompleted: Int
    public var highPriorityCompleted: Int
    public var mediumPriorityCompleted: Int
    public var lowPriorityCompleted: Int

    // AI精度メトリクス
    public var aiSuggestionsAccepted: Int
    public var aiSuggestionsRejected: Int
    public var averageConfidenceScore: Double

    // 時間帯別パフォーマンス
    public var morningTasksCompleted: Int // 5:00-9:00
    public var dayTasksCompleted: Int      // 9:00-17:00
    public var eveningTasksCompleted: Int  // 17:00-21:00
    public var nightTasksCompleted: Int    // 21:00-5:00

    // カテゴリ別統計
    public var categoryCompletionRates: [String: Double]
    public var averageCompletionTime: [String: Double] // カテゴリ別平均完了時間（時間）

    // 朝活特化メトリクス
    public var earlyMorningProductivityScore: Double // 5:00-7:00の生産性スコア
    public var bestProductiveHour: Int?

    // MARK: - Computed Properties

    public var completionRate: Double {
        guard totalTasksCreated > 0 else { return 0 }
        return Double(totalTasksCompleted) / Double(totalTasksCreated)
    }

    public var aiAcceptanceRate: Double {
        let total = aiSuggestionsAccepted + aiSuggestionsRejected
        guard total > 0 else { return 0 }
        return Double(aiSuggestionsAccepted) / Double(total)
    }

    public var priorityDistribution: [String: Double] {
        let total = highPriorityCompleted + mediumPriorityCompleted + lowPriorityCompleted
        guard total > 0 else { return [:] }

        return [
            "high": Double(highPriorityCompleted) / Double(total),
            "medium": Double(mediumPriorityCompleted) / Double(total),
            "low": Double(lowPriorityCompleted) / Double(total)
        ]
    }

    // MARK: - Initializer

    public init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.totalTasksCreated = 0
        self.totalTasksCompleted = 0
        self.highPriorityCompleted = 0
        self.mediumPriorityCompleted = 0
        self.lowPriorityCompleted = 0
        self.aiSuggestionsAccepted = 0
        self.aiSuggestionsRejected = 0
        self.averageConfidenceScore = 0.0
        self.morningTasksCompleted = 0
        self.dayTasksCompleted = 0
        self.eveningTasksCompleted = 0
        self.nightTasksCompleted = 0
        self.categoryCompletionRates = [:]
        self.averageCompletionTime = [:]
        self.earlyMorningProductivityScore = 0.0
    }

    // MARK: - Methods

    public func recordTaskCreated() {
        totalTasksCreated += 1
    }

    public func recordTaskCompleted(task: SmartTask) {
        totalTasksCompleted += 1

        // 優先度別カウント
        switch task.userPriority {
        case .high:
            highPriorityCompleted += 1
        case .medium:
            mediumPriorityCompleted += 1
        case .low:
            lowPriorityCompleted += 1
        }

        // 時間帯別カウント
        let hour = Calendar.current.component(.hour, from: task.completedAt ?? Date())
        switch hour {
        case 5..<9:
            morningTasksCompleted += 1
        case 9..<17:
            dayTasksCompleted += 1
        case 17..<21:
            eveningTasksCompleted += 1
        default:
            nightTasksCompleted += 1
        }

        // カテゴリ別統計更新
        let categoryKey = task.category.rawValue
        let currentRate = categoryCompletionRates[categoryKey] ?? 0
        categoryCompletionRates[categoryKey] = currentRate + 1

        // 朝活スコア更新（5:00-7:00）
        if hour >= 5 && hour < 7 {
            earlyMorningProductivityScore += 1.0
        }
    }

    public func recordAIFeedback(accepted: Bool, confidenceScore: Double) {
        if accepted {
            aiSuggestionsAccepted += 1
        } else {
            aiSuggestionsRejected += 1
        }

        // 信頼度スコアの移動平均を更新
        let totalFeedbacks = aiSuggestionsAccepted + aiSuggestionsRejected
        averageConfidenceScore = (averageConfidenceScore * Double(totalFeedbacks - 1) + confidenceScore) / Double(totalFeedbacks)
    }

    public func calculateBestProductiveHour(from tasks: [SmartTask]) {
        var hourProductivity: [Int: Int] = [:]

        for task in tasks where task.status == .done {
            let hour = Calendar.current.component(.hour, from: task.completedAt ?? Date())
            hourProductivity[hour, default: 0] += 1
        }

        bestProductiveHour = hourProductivity.max(by: { $0.value < $1.value })?.key
    }

    public static func generateWeeklyReport(from analytics: [TaskAnalytics]) -> WeeklyReport {
        WeeklyReport(analytics: analytics)
    }
}

// 週次レポート構造体
public struct WeeklyReport {
    public let totalTasksCompleted: Int
    public let averageCompletionRate: Double
    public let aiAcceptanceRate: Double
    public let bestProductiveTimeSlot: String
    public let mostProductiveCategory: String?
    public let earlyMorningScore: Double

    init(analytics: [TaskAnalytics]) {
        self.totalTasksCompleted = analytics.reduce(0) { $0 + $1.totalTasksCompleted }

        let avgRate = analytics.reduce(0.0) { $0 + $1.completionRate } / Double(max(analytics.count, 1))
        self.averageCompletionRate = avgRate

        let totalAccepted = analytics.reduce(0) { $0 + $1.aiSuggestionsAccepted }
        let totalRejected = analytics.reduce(0) { $0 + $1.aiSuggestionsRejected }
        self.aiAcceptanceRate = Double(totalAccepted) / Double(max(totalAccepted + totalRejected, 1))

        // 時間帯別の生産性判定
        let morningTotal = analytics.reduce(0) { $0 + $1.morningTasksCompleted }
        let dayTotal = analytics.reduce(0) { $0 + $1.dayTasksCompleted }
        let eveningTotal = analytics.reduce(0) { $0 + $1.eveningTasksCompleted }
        let nightTotal = analytics.reduce(0) { $0 + $1.nightTasksCompleted }

        let maxTime = max(morningTotal, dayTotal, eveningTotal, nightTotal)
        if maxTime == morningTotal {
            self.bestProductiveTimeSlot = "朝（5:00-9:00）"
        } else if maxTime == dayTotal {
            self.bestProductiveTimeSlot = "日中（9:00-17:00）"
        } else if maxTime == eveningTotal {
            self.bestProductiveTimeSlot = "夕方（17:00-21:00）"
        } else {
            self.bestProductiveTimeSlot = "夜（21:00-5:00）"
        }

        // カテゴリ別の生産性
        var categoryTotals: [String: Double] = [:]
        for analytic in analytics {
            for (category, count) in analytic.categoryCompletionRates {
                categoryTotals[category, default: 0] += count
            }
        }
        self.mostProductiveCategory = categoryTotals.max(by: { $0.value < $1.value })?.key

        // 朝活スコア
        self.earlyMorningScore = analytics.reduce(0.0) { $0 + $1.earlyMorningProductivityScore } / Double(max(analytics.count, 1))
    }
}