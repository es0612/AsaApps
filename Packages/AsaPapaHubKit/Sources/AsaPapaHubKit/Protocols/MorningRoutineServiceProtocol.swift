import Foundation

// MARK: - 朝活ルーティンサービスプロトコル

@MainActor
public protocol MorningRoutineServiceProtocol: Sendable {
    func fetchRoutine(for date: Date) async throws -> MorningRoutine?
    func createDefaultRoutine(for date: Date) async throws -> MorningRoutine
    func startRoutine(_ routine: MorningRoutine) async throws
    func completeItem(_ item: MorningRoutineItem) async throws
    func skipItem(_ item: MorningRoutineItem) async throws
    func finishRoutine(_ routine: MorningRoutine) async throws
    func fetchRoutineHistory(days: Int) async throws -> [MorningRoutine]
}
