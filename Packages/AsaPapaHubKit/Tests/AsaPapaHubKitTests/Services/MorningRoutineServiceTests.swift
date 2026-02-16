import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("MorningRoutineService テスト")
struct MorningRoutineServiceTests {
    @Test("ルーティン取得 - 存在しない")
    @MainActor func testFetchRoutineNotFound() async throws {
        let service = MockMorningRoutineService()
        let result = try await service.fetchRoutine(for: Date())
        #expect(result == nil)
    }

    @Test("デフォルトルーティン作成")
    @MainActor func testCreateDefaultRoutine() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        #expect(routine.items.count == 3)
        #expect(routine.items.first?.title == "起床")
    }

    @Test("ルーティン開始")
    @MainActor func testStartRoutine() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        try await service.startRoutine(routine)
        #expect(service.startRoutineCalled)
        #expect(routine.startTime != nil)
    }

    @Test("アイテム完了")
    @MainActor func testCompleteItem() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        let item = routine.items.first!
        try await service.completeItem(item)
        #expect(service.completeItemCalled)
        #expect(item.status == .completed)
    }

    @Test("アイテムスキップ")
    @MainActor func testSkipItem() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        let item = routine.items.first!
        try await service.skipItem(item)
        #expect(service.skipItemCalled)
        #expect(item.status == .skipped)
    }

    @Test("ルーティン終了")
    @MainActor func testFinishRoutine() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        try await service.finishRoutine(routine)
        #expect(service.finishRoutineCalled)
        #expect(routine.isCompleted)
        #expect(routine.endTime != nil)
    }

    @Test("ルーティン履歴取得")
    @MainActor func testFetchRoutineHistory() async throws {
        let service = MockMorningRoutineService()
        _ = try await service.createDefaultRoutine(for: Date())
        let history = try await service.fetchRoutineHistory(days: 7)
        #expect(history.count == 1)
    }

    @Test("エラー - ルーティン開始")
    @MainActor func testStartRoutineError() async {
        let service = MockMorningRoutineService()
        service.shouldThrowError = true
        let routine = MorningRoutine()
        do {
            try await service.startRoutine(routine)
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("エラー - アイテム完了")
    @MainActor func testCompleteItemError() async {
        let service = MockMorningRoutineService()
        service.shouldThrowError = true
        let item = MorningRoutineItem(title: "テスト")
        do {
            try await service.completeItem(item)
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("エラー - 取得")
    @MainActor func testFetchError() async {
        let service = MockMorningRoutineService()
        service.shouldThrowError = true
        do {
            _ = try await service.fetchRoutine(for: Date())
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("デフォルトルーティンのアイテム順序")
    @MainActor func testDefaultRoutineItemOrder() async throws {
        let service = MockMorningRoutineService()
        let routine = try await service.createDefaultRoutine(for: Date())
        let sorted = routine.items.sorted { $0.order < $1.order }
        #expect(sorted[0].order == 0)
        #expect(sorted[1].order == 1)
        #expect(sorted[2].order == 2)
    }

    @Test("ルーティン作成エラー")
    @MainActor func testCreateRoutineError() async {
        let service = MockMorningRoutineService()
        service.shouldThrowError = true
        do {
            _ = try await service.createDefaultRoutine(for: Date())
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }
}
