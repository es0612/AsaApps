//
//  Lesson.swift
//  AsaLanguageLearn
//
//  レッスン（学習アイテムのコンテナ）
//

import Foundation
import SwiftData

/// レッスン
/// 複数の学習アイテムをまとめた学習単位
@Model
final class Lesson {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var lessonDescription: String
    var sortOrder: Int
    var isUnlocked: Bool
    var createdAt: Date

    var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \LearningItem.lesson)
    var items: [LearningItem]

    // MARK: - Computed Properties

    var completedItemsCount: Int {
        items.filter { $0.progress?.masteryLevel == .mastered }.count
    }

    var totalItemsCount: Int {
        items.count
    }

    var progressPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }

    var isCompleted: Bool {
        totalItemsCount > 0 && completedItemsCount == totalItemsCount
    }

    var isStarted: Bool {
        items.contains { $0.progress?.isStudied == true }
    }

    var itemsDueForReview: [LearningItem] {
        items.filter { $0.progress?.needsReview == true }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        sortOrder: Int = 0,
        isUnlocked: Bool = true
    ) {
        self.id = id
        self.title = title
        self.lessonDescription = description
        self.sortOrder = sortOrder
        self.isUnlocked = isUnlocked
        self.createdAt = Date()
        self.items = []
    }
}

// MARK: - Sample Data

extension Lesson {
    static var sampleMorningGreetings: Lesson {
        Lesson(
            title: "朝の挨拶",
            description: "Good morning などの朝の挨拶表現",
            sortOrder: 0
        )
    }

    static var sampleAfternoonGreetings: Lesson {
        Lesson(
            title: "午後の挨拶",
            description: "Good afternoon などの午後の挨拶表現",
            sortOrder: 1
        )
    }
}
