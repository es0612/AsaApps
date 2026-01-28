import Testing
import Foundation
@testable import AsaPhotoEditor

// MARK: - HistoryManager Tests
@Suite("HistoryManager Tests")
struct HistoryManagerTests {
    // MARK: - Initial State

    @Test("初期状態ではundo/redoができない")
    func testInitialState() {
        let manager = HistoryManager<EditState>()
        #expect(manager.canUndo == false)
        #expect(manager.canRedo == false)
        #expect(manager.historyCount == 0)
    }

    // MARK: - Record

    @Test("状態を記録するとundo可能になる")
    func testRecordEnablesUndo() {
        let manager = HistoryManager<EditState>()
        let state = EditState.default

        manager.record(state)

        #expect(manager.canUndo == true)
        #expect(manager.historyCount == 1)
    }

    @Test("同じ状態を連続で記録しても1回分のみ")
    func testDuplicateRecordIgnored() {
        let manager = HistoryManager<EditState>()
        let state = EditState.default

        manager.record(state)
        manager.record(state)
        manager.record(state)

        #expect(manager.historyCount == 1)
    }

    @Test("最大履歴数を超えると古いものが削除される")
    func testMaxHistoryEnforced() {
        let manager = HistoryManager<EditState>(maxHistoryCount: 3)

        for i in 0..<5 {
            var state = EditState.default
            state.adjustment.brightness = Double(i) * 0.1
            manager.record(state)
        }

        #expect(manager.historyCount == 3)
    }

    // MARK: - Undo

    @Test("undoで前の状態に戻る")
    func testUndo() {
        let manager = HistoryManager<EditState>()

        var state1 = EditState.default
        state1.adjustment.brightness = 0.1
        manager.record(state1)

        var state2 = EditState.default
        state2.adjustment.brightness = 0.5

        let previousState = manager.undo(currentState: state2)

        #expect(previousState != nil)
        #expect(previousState?.adjustment.brightness == 0.1)
    }

    @Test("undo後はredo可能になる")
    func testUndoEnablesRedo() {
        let manager = HistoryManager<EditState>()

        let state1 = EditState.default
        manager.record(state1)

        var state2 = EditState.default
        state2.adjustment.brightness = 0.5

        _ = manager.undo(currentState: state2)

        #expect(manager.canRedo == true)
    }

    // MARK: - Redo

    @Test("redoで次の状態に進む")
    func testRedo() {
        let manager = HistoryManager<EditState>()

        var state1 = EditState.default
        state1.adjustment.brightness = 0.1
        manager.record(state1)

        var state2 = EditState.default
        state2.adjustment.brightness = 0.5

        // undo
        let previousState = manager.undo(currentState: state2)

        // redo
        let nextState = manager.redo(currentState: previousState!)

        #expect(nextState != nil)
        #expect(nextState?.adjustment.brightness == 0.5)
    }

    @Test("新しいアクションを記録するとredoスタックがクリアされる")
    func testRecordClearsRedoStack() {
        let manager = HistoryManager<EditState>()

        var state1 = EditState.default
        state1.adjustment.brightness = 0.1
        manager.record(state1)

        var state2 = EditState.default
        state2.adjustment.brightness = 0.5

        // undo
        let previousState = manager.undo(currentState: state2)

        // 新しい状態を記録
        var newState = EditState.default
        newState.adjustment.brightness = 0.8
        manager.record(newState)

        #expect(manager.canRedo == false)
    }

    // MARK: - Clear

    @Test("クリアで履歴がリセットされる")
    func testClear() {
        let manager = HistoryManager<EditState>()

        let state = EditState.default
        manager.record(state)

        manager.clear()

        #expect(manager.canUndo == false)
        #expect(manager.canRedo == false)
        #expect(manager.historyCount == 0)
    }

    // MARK: - Reset

    @Test("リセットで初期状態が設定される")
    func testReset() {
        let manager = HistoryManager<EditState>()

        var state1 = EditState.default
        state1.adjustment.brightness = 0.5
        manager.record(state1)

        let initialState = EditState.default
        manager.reset(with: initialState)

        #expect(manager.historyCount == 1)
        #expect(manager.canUndo == true)
    }
}

// MARK: - EditState Tests
@Suite("EditState Tests")
struct EditStateTests {
    @Test("デフォルト状態のisDefaultがtrue")
    func testDefaultIsDefault() {
        let state = EditState.default
        #expect(state.isDefault == true)
    }

    @Test("変更後のisDefaultがfalse")
    func testModifiedIsNotDefault() {
        var state = EditState.default
        state.adjustment.brightness = 0.5
        #expect(state.isDefault == false)
    }

    @Test("Codableのテスト")
    func testCodable() throws {
        var original = EditState.default
        original.adjustment.brightness = 0.3
        original.filterSettings.preset = .sepia

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EditState.self, from: data)

        #expect(decoded.adjustment.brightness == original.adjustment.brightness)
        #expect(decoded.filterSettings.preset == original.filterSettings.preset)
    }
}
