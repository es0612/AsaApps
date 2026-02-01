//
//  VRSceneViewModel.swift
//  AsaVRDiary
//
//  VRシーン状態管理ViewModel
//

import Foundation
import RealityKit
import SwiftUI

/// VRシーン状態管理ViewModel
@MainActor
@Observable
final class VRSceneViewModel {

    // MARK: - Properties

    /// 表示モード
    var displayMode: VRSceneService.DisplayMode = .grid {
        didSet {
            if oldValue != displayMode {
                needsSceneUpdate = true
            }
        }
    }

    /// シーン更新が必要かどうか
    var needsSceneUpdate: Bool = false

    /// 選択中の日記ID
    var selectedEntryId: UUID?

    /// VRシーンサービス
    let sceneService: VRSceneService

    /// ズームレベル（1.0 = 標準）
    var zoomLevel: Float = 1.0

    /// カメラオフセット
    var cameraOffset: SIMD3<Float> = .zero

    /// 回転角度（Y軸）
    var rotationAngle: Float = 0.0

    /// アニメーション有効
    var animationsEnabled: Bool = true

    /// シーン設定
    var configuration: VRSceneConfiguration = .default

    // MARK: - Initialization

    init(sceneService: VRSceneService? = nil) {
        self.sceneService = sceneService ?? VRSceneService()
    }

    // MARK: - Public Methods

    /// シーンを構築してアンカーを返す
    func buildScene(entries: [DiaryEntry]) -> AnchorEntity {
        let anchor = sceneService.buildScene(entries: entries, displayMode: displayMode)
        needsSceneUpdate = false
        return anchor
    }

    /// シーンをクリア
    func clearScene() {
        sceneService.clearEntities()
        selectedEntryId = nil
    }

    /// 表示モードを切り替え
    func switchDisplayMode(to mode: VRSceneService.DisplayMode, entries: [DiaryEntry]) {
        displayMode = mode
        sceneService.switchDisplayMode(to: mode, entries: entries, animated: animationsEnabled)
    }

    /// 日記カードを選択
    func selectEntry(_ entryId: UUID?) {
        // 以前の選択を解除
        if let previousId = selectedEntryId,
           let previousEntity = sceneService.getEntity(for: previousId) {
            previousEntity.selectDiaryCard(selected: false)
        }

        selectedEntryId = entryId

        // 新しい選択を適用
        if let id = entryId,
           let entity = sceneService.getEntity(for: id) {
            entity.selectDiaryCard(selected: true)
        }
    }

    /// 日記カードをフリップ
    func flipEntry(_ entryId: UUID) {
        guard let entity = sceneService.getEntity(for: entryId) else { return }
        entity.flipDiaryCard()
    }

    /// エンティティを更新
    func updateEntry(_ entry: DiaryEntry) {
        sceneService.updateEntity(for: entry)
    }

    /// エンティティを削除
    func removeEntry(_ entryId: UUID) {
        sceneService.removeEntity(for: entryId)
        if selectedEntryId == entryId {
            selectedEntryId = nil
        }
    }

    /// ズームイン
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 3.0)
    }

    /// ズームアウト
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.5)
    }

    /// ズームをリセット
    func resetZoom() {
        zoomLevel = 1.0
    }

    /// カメラを移動
    func moveCamera(by offset: SIMD3<Float>) {
        cameraOffset += offset
    }

    /// カメラをリセット
    func resetCamera() {
        cameraOffset = .zero
        rotationAngle = 0.0
        zoomLevel = 1.0
    }

    /// 左に回転
    func rotateLeft() {
        rotationAngle -= Float.pi / 6  // 30度
    }

    /// 右に回転
    func rotateRight() {
        rotationAngle += Float.pi / 6  // 30度
    }

    /// シーン更新完了をマーク
    func markSceneUpdated() {
        needsSceneUpdate = false
    }

    /// タップされた座標からエンティティを検索
    func findEntity(at position: CGPoint, in size: CGSize, entities: [UUID: ModelEntity]) -> UUID? {
        // 簡易的な実装: 最も近いエンティティを返す
        // 実際のプロダクションではレイキャストを使用すべき
        return nil
    }
}

// MARK: - VRGestureState

/// VRジェスチャー状態
struct VRGestureState {
    var isPanning: Bool = false
    var isPinching: Bool = false
    var isRotating: Bool = false
    var lastPanLocation: CGPoint = .zero
    var lastPinchScale: CGFloat = 1.0
    var lastRotation: CGFloat = 0.0
}
