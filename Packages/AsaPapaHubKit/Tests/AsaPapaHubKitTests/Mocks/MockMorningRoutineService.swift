import Foundation
@testable import AsaPapaHubKit

@MainActor
final class MockMorningRoutineService: MorningRoutineServiceProtocol {
    var routines: [MorningRoutine] = []
    var shouldThrowError = false
    var startRoutineCalled = false
    var completeItemCalled = false
    var skipItemCalled = false
    var finishRoutineCalled = false

    func fetchRoutine(for date: Date) async throws -> MorningRoutine? {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        let calendar = Calendar.current
        return routines.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func createDefaultRoutine(for date: Date) async throws -> MorningRoutine {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        let routine = MorningRoutine(date: date)
        let items = [
            MorningRoutineItem(title: "起床", order: 0, estimatedMinutes: 5, iconName: "cup.and.saucer.fill"),
            MorningRoutineItem(title: "ストレッチ", order: 1, estimatedMinutes: 10, iconName: "figure.flexibility"),
            MorningRoutineItem(title: "瞑想", order: 2, estimatedMinutes: 10, iconName: "brain.head.profile"),
        ]
        for item in items {
            item.routine = routine
            routine.items.append(item)
        }
        routines.append(routine)
        return routine
    }

    func startRoutine(_ routine: MorningRoutine) async throws {
        if shouldThrowError { throw PapaHubError.routineAlreadyStarted }
        startRoutineCalled = true
        routine.startTime = Date()
    }

    func completeItem(_ item: MorningRoutineItem) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        completeItemCalled = true
        item.status = .completed
    }

    func skipItem(_ item: MorningRoutineItem) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        skipItemCalled = true
        item.status = .skipped
    }

    func finishRoutine(_ routine: MorningRoutine) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        finishRoutineCalled = true
        routine.endTime = Date()
        routine.isCompleted = true
    }

    func fetchRoutineHistory(days: Int) async throws -> [MorningRoutine] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        return routines
    }
}
