import Foundation
import SwiftData

// MARK: - 朝活ルーティンサービス

@MainActor
public final class MorningRoutineService: MorningRoutineServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchRoutine(for date: Date) async throws -> MorningRoutine? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<MorningRoutine>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func createDefaultRoutine(for date: Date) async throws -> MorningRoutine {
        let routine = MorningRoutine(date: date, targetDurationMinutes: 60)
        let defaultItems: [(String, Int, String)] = [
            ("起床・水分補給", 5, "cup.and.saucer.fill"),
            ("ストレッチ", 10, "figure.flexibility"),
            ("瞑想", 10, "brain.head.profile"),
            ("朝食準備・食事", 20, "fork.knife"),
            ("学習・読書", 15, "book.fill"),
        ]
        for (index, item) in defaultItems.enumerated() {
            let routineItem = MorningRoutineItem(
                title: item.0,
                order: index,
                estimatedMinutes: item.1,
                iconName: item.2
            )
            routineItem.routine = routine
            routine.items.append(routineItem)
        }
        modelContext.insert(routine)
        try modelContext.save()
        return routine
    }

    public func startRoutine(_ routine: MorningRoutine) async throws {
        guard routine.startTime == nil else {
            throw PapaHubError.routineAlreadyStarted
        }
        routine.startTime = Date()
        if let firstItem = routine.items.sorted(by: { $0.order < $1.order }).first {
            firstItem.status = .inProgress
        }
        try modelContext.save()
    }

    public func completeItem(_ item: MorningRoutineItem) async throws {
        item.status = .completed
        try modelContext.save()
    }

    public func skipItem(_ item: MorningRoutineItem) async throws {
        item.status = .skipped
        try modelContext.save()
    }

    public func finishRoutine(_ routine: MorningRoutine) async throws {
        routine.endTime = Date()
        routine.isCompleted = true
        let completedCount = routine.items.filter { $0.status == .completed }.count
        let total = routine.items.count
        routine.totalScore = total > 0 ? Int(Double(completedCount) / Double(total) * 100.0) : 0
        try modelContext.save()
    }

    public func fetchRoutineHistory(days: Int) async throws -> [MorningRoutine] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let descriptor = FetchDescriptor<MorningRoutine>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
