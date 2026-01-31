//
//  Course.swift
//  AsaLanguageLearn
//
//  学習コース（レッスンのコンテナ）
//

import Foundation
import SwiftData

/// 学習コース
/// 複数のレッスンをまとめた学習単位
@Model
final class Course {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var categoryRawValue: String
    var difficulty: Int  // 1-5
    var estimatedMinutes: Int
    var sortOrder: Int
    var isUnlocked: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Lesson.course)
    var lessons: [Lesson]

    // MARK: - Computed Properties

    var category: ContentCategory {
        get { ContentCategory(rawValue: categoryRawValue) ?? .greetings }
        set { categoryRawValue = newValue.rawValue }
    }

    var completedLessonsCount: Int {
        lessons.filter { $0.isCompleted }.count
    }

    var totalLessonsCount: Int {
        lessons.count
    }

    var progressPercentage: Double {
        guard totalLessonsCount > 0 else { return 0 }
        return Double(completedLessonsCount) / Double(totalLessonsCount)
    }

    var isCompleted: Bool {
        totalLessonsCount > 0 && completedLessonsCount == totalLessonsCount
    }

    var difficultyStars: String {
        String(repeating: "★", count: difficulty) + String(repeating: "☆", count: 5 - difficulty)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: ContentCategory,
        difficulty: Int = 1,
        estimatedMinutes: Int = 10,
        sortOrder: Int = 0,
        isUnlocked: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.categoryRawValue = category.rawValue
        self.difficulty = max(1, min(5, difficulty))
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.isUnlocked = isUnlocked
        self.createdAt = Date()
        self.lessons = []
    }
}

// MARK: - Sample Data

extension Course {
    static var sampleGreetingsCourse: Course {
        let course = Course(
            title: "基本の挨拶",
            subtitle: "英語での挨拶表現をマスターしよう",
            category: .greetings,
            difficulty: 1,
            estimatedMinutes: 15
        )
        return course
    }

    static var sampleTravelCourse: Course {
        let course = Course(
            title: "旅行英会話",
            subtitle: "空港・ホテル・観光で使えるフレーズ",
            category: .travel,
            difficulty: 2,
            estimatedMinutes: 30
        )
        return course
    }
}
