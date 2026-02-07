import Foundation
import Testing

@testable import AsaPhotoStoryKit

// MARK: - HistoryManager テスト

@Suite("HistoryManager テスト")
struct HistoryManagerTests {
    @Test("HistoryManager record/undo/redo サイクル")
    func testRecordUndoRedoCycle() {
        let manager = HistoryManager<StoryEditState>()
        let id1 = UUID()
        let id2 = UUID()

        let state1 = StoryEditState(pageOrders: [id1: 0], currentPageId: id1)
        let state2 = StoryEditState(pageOrders: [id1: 0, id2: 1], currentPageId: id2)
        let currentState = StoryEditState(pageOrders: [id1: 1, id2: 0], currentPageId: id1)

        // record
        manager.record(state1)
        manager.record(state2)
        #expect(manager.canUndo == true)
        #expect(manager.canRedo == false)
        #expect(manager.historyCount == 2)

        // undo
        let undoneState = manager.undo(currentState: currentState)
        #expect(undoneState == state2)
        #expect(manager.canRedo == true)

        // redo
        let redoneState = manager.redo(currentState: state2)
        #expect(redoneState == currentState)
    }

    @Test("HistoryManager maxHistoryCount 超過時の古い履歴削除")
    func testMaxHistoryCountTruncation() {
        let manager = HistoryManager<StoryEditState>(maxHistoryCount: 3)

        // 4つの状態を記録（最大3）
        for i in 0 ..< 4 {
            let id = UUID()
            let state = StoryEditState(pageOrders: [id: i], currentPageId: id)
            manager.record(state)
        }

        // 最大3つまで保持
        #expect(manager.historyCount == 3)
    }

    @Test("HistoryManager clear - 全履歴クリア")
    func testClear() {
        let manager = HistoryManager<StoryEditState>()
        let id = UUID()

        let state1 = StoryEditState(pageOrders: [id: 0])
        let state2 = StoryEditState(pageOrders: [id: 1])
        manager.record(state1)
        manager.record(state2)

        #expect(manager.canUndo == true)

        manager.clear()
        #expect(manager.canUndo == false)
        #expect(manager.canRedo == false)
        #expect(manager.historyCount == 0)
    }

    @Test("HistoryManager 同じ状態のrecordスキップ")
    func testDuplicateRecordSkip() {
        let manager = HistoryManager<StoryEditState>()
        let id = UUID()
        let state = StoryEditState(pageOrders: [id: 0], currentPageId: id)

        manager.record(state)
        manager.record(state) // 同じ状態 → スキップされるはず
        manager.record(state) // 同じ状態 → スキップされるはず

        #expect(manager.historyCount == 1)
    }
}

// MARK: - ExportSettings テスト

@Suite("ExportSettings テスト")
struct ExportSettingsTests {
    @Test("ExportSettings フォーマットバリデーション - 全フォーマットの確認")
    func testExportFormatValidation() {
        for format in ExportFormat.allCases {
            #expect(!format.displayName.isEmpty)
            #expect(!format.fileExtension.isEmpty)
            #expect(!format.rawValue.isEmpty)
        }

        // Codable テスト
        let settings = ExportSettings(format: .pdf, resolution: .uhd4K, quality: 0.95)
        let encoded = try? JSONEncoder().encode(settings)
        #expect(encoded != nil)

        if let encoded {
            let decoded = try? JSONDecoder().decode(ExportSettings.self, from: encoded)
            #expect(decoded == settings)
        }
    }

    @Test("ExportResolution 各解像度の幅と高さ")
    func testExportResolutionDimensions() {
        #expect(ExportResolution.hd1080p.width == 1920)
        #expect(ExportResolution.hd1080p.height == 1080)
        #expect(ExportResolution.hd1440p.width == 2560)
        #expect(ExportResolution.hd1440p.height == 1440)
        #expect(ExportResolution.uhd4K.width == 3840)
        #expect(ExportResolution.uhd4K.height == 2160)
    }
}

// MARK: - StoryEditState テスト

@Suite("StoryEditState テスト")
struct StoryEditStateTests {
    @Test("StoryEditState デフォルト値")
    func testDefault() {
        let state = StoryEditState.default
        #expect(state.pageOrders.isEmpty)
        #expect(state.currentPageId == nil)
    }

    @Test("StoryEditState Codable エンコード/デコード")
    func testCodable() {
        let id1 = UUID()
        let id2 = UUID()
        let state = StoryEditState(
            pageOrders: [id1: 0, id2: 1],
            currentPageId: id1
        )

        let encoded = try? JSONEncoder().encode(state)
        #expect(encoded != nil)

        if let encoded {
            let decoded = try? JSONDecoder().decode(StoryEditState.self, from: encoded)
            #expect(decoded == state)
        }
    }

    @Test("StoryEditState Equatable 比較")
    func testEquatable() {
        let id = UUID()
        let state1 = StoryEditState(pageOrders: [id: 0], currentPageId: id)
        let state2 = StoryEditState(pageOrders: [id: 0], currentPageId: id)
        let state3 = StoryEditState(pageOrders: [id: 1], currentPageId: id)

        #expect(state1 == state2)
        #expect(state1 != state3)
    }
}

// MARK: - PhotoStoryError テスト

@Suite("PhotoStoryError テスト")
struct PhotoStoryErrorTests {
    @Test("PhotoStoryError 全ケースのエラー説明が存在する")
    func testAllErrorDescriptions() {
        let errors: [PhotoStoryError] = [
            .storyNotFound,
            .pageNotFound,
            .elementNotFound,
            .imageLoadFailed,
            .imageSaveFailed,
            .imageResizeFailed,
            .exportFailed("テスト"),
            .captionGenerationFailed,
            .invalidTemplate,
            .invalidLayout,
            .dataCorruption,
            .photoPickerFailed,
            .visionAnalysisFailed,
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }

        // exportFailed は詳細メッセージを含む
        let exportError = PhotoStoryError.exportFailed("動画生成失敗")
        #expect(exportError.errorDescription?.contains("動画生成失敗") == true)
    }
}
