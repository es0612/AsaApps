//
//  VRSceneViewModelTests.swift
//  AsaVRDiaryTests
//
//  VRSceneViewModelのテスト
//

import Testing
import Foundation
@testable import AsaVRDiary

@Suite("VRSceneViewModel Tests")
@MainActor
struct VRSceneViewModelTests {

    // MARK: - Initialization Tests

    @Test("初期化テスト")
    func testInitialization() {
        let viewModel = VRSceneViewModel()

        #expect(viewModel.displayMode == .grid)
        #expect(viewModel.selectedEntryId == nil)
        #expect(viewModel.zoomLevel == 1.0)
        #expect(viewModel.animationsEnabled == true)
    }

    // MARK: - Display Mode Tests

    @Test("表示モード変更テスト")
    func testDisplayModeChange() {
        let viewModel = VRSceneViewModel()

        viewModel.displayMode = .timeline
        #expect(viewModel.displayMode == .timeline)
        #expect(viewModel.needsSceneUpdate == true)

        viewModel.markSceneUpdated()
        #expect(viewModel.needsSceneUpdate == false)
    }

    // MARK: - Selection Tests

    @Test("エントリー選択テスト")
    func testSelectEntry() {
        let viewModel = VRSceneViewModel()
        let entryId = UUID()

        viewModel.selectEntry(entryId)
        #expect(viewModel.selectedEntryId == entryId)

        viewModel.selectEntry(nil)
        #expect(viewModel.selectedEntryId == nil)
    }

    // MARK: - Zoom Tests

    @Test("ズームインテスト")
    func testZoomIn() {
        let viewModel = VRSceneViewModel()
        let initialZoom = viewModel.zoomLevel

        viewModel.zoomIn()
        #expect(viewModel.zoomLevel > initialZoom)
    }

    @Test("ズームアウトテスト")
    func testZoomOut() {
        let viewModel = VRSceneViewModel()
        let initialZoom = viewModel.zoomLevel

        viewModel.zoomOut()
        #expect(viewModel.zoomLevel < initialZoom)
    }

    @Test("ズームリセットテスト")
    func testResetZoom() {
        let viewModel = VRSceneViewModel()

        viewModel.zoomIn()
        viewModel.zoomIn()
        viewModel.resetZoom()

        #expect(viewModel.zoomLevel == 1.0)
    }

    @Test("ズーム上限テスト")
    func testZoomUpperLimit() {
        let viewModel = VRSceneViewModel()

        // 何度もズームイン
        for _ in 0..<20 {
            viewModel.zoomIn()
        }

        #expect(viewModel.zoomLevel <= 3.0)
    }

    @Test("ズーム下限テスト")
    func testZoomLowerLimit() {
        let viewModel = VRSceneViewModel()

        // 何度もズームアウト
        for _ in 0..<20 {
            viewModel.zoomOut()
        }

        #expect(viewModel.zoomLevel >= 0.5)
    }

    // MARK: - Camera Tests

    @Test("カメラ移動テスト")
    func testMoveCamera() {
        let viewModel = VRSceneViewModel()

        viewModel.moveCamera(by: SIMD3<Float>(1.0, 2.0, 3.0))
        #expect(viewModel.cameraOffset == SIMD3<Float>(1.0, 2.0, 3.0))

        viewModel.moveCamera(by: SIMD3<Float>(0.5, 0.5, 0.5))
        #expect(viewModel.cameraOffset == SIMD3<Float>(1.5, 2.5, 3.5))
    }

    @Test("カメラリセットテスト")
    func testResetCamera() {
        let viewModel = VRSceneViewModel()

        viewModel.moveCamera(by: SIMD3<Float>(1.0, 2.0, 3.0))
        viewModel.zoomIn()
        viewModel.rotateRight()

        viewModel.resetCamera()

        #expect(viewModel.cameraOffset == .zero)
        #expect(viewModel.zoomLevel == 1.0)
        #expect(viewModel.rotationAngle == 0.0)
    }

    // MARK: - Rotation Tests

    @Test("左回転テスト")
    func testRotateLeft() {
        let viewModel = VRSceneViewModel()
        let initialRotation = viewModel.rotationAngle

        viewModel.rotateLeft()
        #expect(viewModel.rotationAngle < initialRotation)
    }

    @Test("右回転テスト")
    func testRotateRight() {
        let viewModel = VRSceneViewModel()
        let initialRotation = viewModel.rotationAngle

        viewModel.rotateRight()
        #expect(viewModel.rotationAngle > initialRotation)
    }

    // MARK: - Remove Entry Tests

    @Test("エントリー削除後の選択解除テスト")
    func testRemoveEntryDeselectsIfSelected() {
        let viewModel = VRSceneViewModel()
        let entryId = UUID()

        viewModel.selectEntry(entryId)
        #expect(viewModel.selectedEntryId == entryId)

        viewModel.removeEntry(entryId)
        #expect(viewModel.selectedEntryId == nil)
    }
}

// MARK: - VRSceneConfiguration Tests

@Suite("VRSceneConfiguration Tests")
struct VRSceneConfigurationTests {

    @Test("デフォルト設定テスト")
    func testDefaultConfiguration() {
        let config = VRSceneConfiguration.default

        #expect(config.displayMode == .grid)
        #expect(config.showAllEntries == true)
        #expect(config.maxVisibleEntries == 50)
        #expect(config.enableAnimations == true)
        #expect(config.cardScale == 1.0)
    }
}

// MARK: - VRGestureState Tests

@Suite("VRGestureState Tests")
struct VRGestureStateTests {

    @Test("初期状態テスト")
    func testInitialState() {
        let state = VRGestureState()

        #expect(state.isPanning == false)
        #expect(state.isPinching == false)
        #expect(state.isRotating == false)
        #expect(state.lastPanLocation == .zero)
        #expect(state.lastPinchScale == 1.0)
        #expect(state.lastRotation == 0.0)
    }
}
