import Foundation
import SwiftData

@Model
final class Habit {
    // MARK: - Properties

    var id: UUID
    var name: String
    var habitDescription: String
    var category: HabitCategory
    var icon: String
    var color: String
    var targetFrequency: TargetFrequency
    var reminderTime: Date?
    var isActive: Bool
    var createdAt: Date
    var modifiedAt: Date

    // 統計用プロパティ
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int

    // リレーション
    @Relationship(deleteRule: .cascade, inverse: \HabitRecord.habit)
    var records: [HabitRecord]

    // MARK: - Initialization

    init(
        name: String,
        habitDescription: String = "",
        category: HabitCategory,
        icon: String = "star.fill",
        color: String = "AsaCoffeeBrown",
        targetFrequency: TargetFrequency = .daily,
        reminderTime: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.category = category
        self.icon = icon
        self.color = color
        self.targetFrequency = targetFrequency
        self.reminderTime = reminderTime
        self.isActive = isActive
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.records = []
    }
}

// MARK: - Supporting Types

enum HabitCategory: String, CaseIterable, Codable {
    case health = "健康"
    case learning = "学習"
    case work = "仕事"
    case hobby = "趣味"
    case lifestyle = "生活"
    case exercise = "運動"
    case mindfulness = "マインドフルネス"
    case social = "社交"

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .work: return "briefcase.fill"
        case .hobby: return "star.fill"
        case .lifestyle: return "house.fill"
        case .exercise: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        case .social: return "person.2.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .health: return "AsaSoftCream"
        case .learning: return "AsaCoffeeBrown"
        case .work: return "AsaDarkSlate"
        case .hobby: return "AsaMocha"
        case .lifestyle: return "AsaMutedSage"
        case .exercise: return "AsaCoffeeBrown"
        case .mindfulness: return "AsaSoftCream"
        case .social: return "AsaMocha"
        }
    }
}

enum TargetFrequency: String, CaseIterable, Codable {
    case daily = "毎日"
    case weekdays = "平日"
    case weekends = "週末"
    case weekly3 = "週3回"
    case weekly5 = "週5回"
    case custom = "カスタム"

    var requiredDaysPerWeek: Int {
        switch self {
        case .daily: return 7
        case .weekdays: return 5
        case .weekends: return 2
        case .weekly3: return 3
        case .weekly5: return 5
        case .custom: return 0
        }
    }
}

// MARK: - Computed Properties

extension Habit {
    var isCompletedToday: Bool {
        let calendar = Calendar.current
        return records.contains { record in
            calendar.isDateInToday(record.completedAt)
        }
    }

    var completionRate: Double {
        guard !records.isEmpty else { return 0 }

        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return 0 }

        let expectedCompletions = calculateExpectedCompletions(days: daysSinceCreation)
        guard expectedCompletions > 0 else { return 0 }

        return Double(totalCompletions) / Double(expectedCompletions) * 100
    }

    private func calculateExpectedCompletions(days: Int) -> Int {
        switch targetFrequency {
        case .daily:
            return days
        case .weekdays:
            return Int(Double(days) * (5.0 / 7.0))
        case .weekends:
            return Int(Double(days) * (2.0 / 7.0))
        case .weekly3:
            return Int(Double(days) * (3.0 / 7.0))
        case .weekly5:
            return Int(Double(days) * (5.0 / 7.0))
        case .custom:
            return days // デフォルトは毎日
        }
    }

    func updateStreak() {
        let sortedRecords = records.sorted { $0.completedAt > $1.completedAt }
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()

        for record in sortedRecords {
            if calendar.isDate(record.completedAt, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if let daysBetween = calendar.dateComponents([.day], from: record.completedAt, to: checkDate).day,
                      daysBetween <= 1 {
                streak += 1
                checkDate = record.completedAt
            } else {
                break
            }
        }

        currentStreak = streak
        if streak > longestStreak {
            longestStreak = streak
        }
    }
}