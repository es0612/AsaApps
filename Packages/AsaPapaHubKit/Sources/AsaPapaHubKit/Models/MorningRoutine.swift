import Foundation
import SwiftData

// MARK: - 朝活ルーティン

@Model
public final class MorningRoutine {
    public var id: UUID
    public var date: Date
    public var startTime: Date?
    public var endTime: Date?
    public var targetDurationMinutes: Int
    @Relationship(deleteRule: .cascade, inverse: \MorningRoutineItem.routine)
    public var items: [MorningRoutineItem]
    public var isCompleted: Bool
    public var totalScore: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        targetDurationMinutes: Int = 60,
        items: [MorningRoutineItem] = [],
        isCompleted: Bool = false,
        totalScore: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.targetDurationMinutes = targetDurationMinutes
        self.items = items
        self.isCompleted = isCompleted
        self.totalScore = totalScore
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    public var completionRate: Double {
        guard !items.isEmpty else { return 0.0 }
        let completed = items.filter { $0.status == .completed }.count
        return Double(completed) / Double(items.count)
    }

    public var actualDurationMinutes: Int? {
        guard let start = startTime, let end = endTime else { return nil }
        return Int(end.timeIntervalSince(start) / 60.0)
    }

    public var completedItemsCount: Int {
        items.filter { $0.status == .completed }.count
    }
}
