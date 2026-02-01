//
//  VRSceneService.swift
//  AsaVRDiary
//
//  VRシーン構築サービス
//

import Foundation
import RealityKit
import SwiftUI

// MARK: - VRSceneService

/// VRシーン構築サービス
@MainActor
final class VRSceneService {

    // MARK: - Types

    /// 表示モード
    enum DisplayMode: String, CaseIterable, Sendable {
        case timeline = "timeline"   // タイムライン表示
        case grid = "grid"           // グリッド表示
        case floating = "floating"   // フローティング表示

        var displayName: String {
            switch self {
            case .timeline: return "タイムライン"
            case .grid: return "グリッド"
            case .floating: return "フローティング"
            }
        }

        var icon: String {
            switch self {
            case .timeline: return "chart.line.uptrend.xyaxis"
            case .grid: return "square.grid.3x3"
            case .floating: return "bubble.middle.bottom"
            }
        }
    }

    // MARK: - Properties

    private(set) var entities: [UUID: ModelEntity] = [:]
    private(set) var anchorEntity: AnchorEntity?

    // MARK: - Public Methods

    /// シーンを構築しアンカーを返す
    func buildScene(
        entries: [DiaryEntry],
        displayMode: DisplayMode
    ) -> AnchorEntity {
        // 既存エンティティをクリア
        clearEntities()

        // アンカーを作成
        let anchor = AnchorEntity(world: .zero)
        anchorEntity = anchor

        // 日記エンティティを作成して配置
        let referenceDate = entries.first?.date ?? Date()

        for (index, entry) in entries.enumerated() {
            let entity = DiaryEntityRenderer.createDiaryEntity(for: entry)

            // 位置を計算
            let position: SIMD3<Float>
            switch displayMode {
            case .timeline:
                position = DiaryEntityRenderer.calculateTimelinePosition(
                    for: entry,
                    referenceDate: referenceDate,
                    index: index
                )
            case .grid:
                position = DiaryEntityRenderer.calculateGridPosition(index: index)
            case .floating:
                position = calculateFloatingPosition(index: index, total: entries.count)
            }

            entity.position = position

            // カスタムVR位置がある場合はそちらを使用
            if entry.hasCustomVRPosition,
               let x = entry.vrPositionX,
               let y = entry.vrPositionY,
               let z = entry.vrPositionZ {
                entity.position = SIMD3<Float>(x, y, z)
            }

            anchor.addChild(entity)
            entities[entry.id] = entity
        }

        return anchor
    }

    /// エンティティをクリア
    func clearEntities() {
        entities.removeAll()
        anchorEntity = nil
    }

    /// 特定の日記エンティティを取得
    func getEntity(for entryId: UUID) -> ModelEntity? {
        entities[entryId]
    }

    /// すべての日記エンティティを取得
    func getAllEntities() -> [UUID: ModelEntity] {
        entities
    }

    /// 日記エンティティを更新
    func updateEntity(for entry: DiaryEntry) {
        guard let oldEntity = entities[entry.id],
              let parent = oldEntity.parent else { return }

        let position = oldEntity.position

        // 古いエンティティを削除
        parent.removeChild(oldEntity)

        // 新しいエンティティを作成
        let newEntity = DiaryEntityRenderer.createDiaryEntity(for: entry)
        newEntity.position = position

        parent.addChild(newEntity)
        entities[entry.id] = newEntity
    }

    /// 日記エンティティを削除
    func removeEntity(for entryId: UUID) {
        guard let entity = entities[entryId] else { return }
        entity.removeFromParent()
        entities.removeValue(forKey: entryId)
    }

    /// カメラ位置からの可視エンティティを取得
    func getVisibleEntities(from cameraPosition: SIMD3<Float>, maxDistance: Float = 2.0) -> [UUID] {
        entities.compactMap { id, entity in
            let distance = simd_distance(entity.position, cameraPosition)
            return distance <= maxDistance ? id : nil
        }
    }

    /// 表示モードを切り替え
    func switchDisplayMode(
        to mode: DisplayMode,
        entries: [DiaryEntry],
        animated: Bool = true
    ) {
        let referenceDate = entries.first?.date ?? Date()

        for (index, entry) in entries.enumerated() {
            guard let entity = entities[entry.id] else { continue }

            let newPosition: SIMD3<Float>
            switch mode {
            case .timeline:
                newPosition = DiaryEntityRenderer.calculateTimelinePosition(
                    for: entry,
                    referenceDate: referenceDate,
                    index: index
                )
            case .grid:
                newPosition = DiaryEntityRenderer.calculateGridPosition(index: index)
            case .floating:
                newPosition = calculateFloatingPosition(index: index, total: entries.count)
            }

            if animated {
                let transform = Transform(
                    scale: entity.scale,
                    rotation: entity.orientation,
                    translation: newPosition
                )
                entity.move(
                    to: transform,
                    relativeTo: entity.parent,
                    duration: 0.5,
                    timingFunction: .easeInOut
                )
            } else {
                entity.position = newPosition
            }
        }
    }

    // MARK: - Private Methods

    /// フローティング位置を計算（螺旋状配置）
    private func calculateFloatingPosition(index: Int, total: Int) -> SIMD3<Float> {
        let angle = Float(index) * (Float.pi * 2 / Float(max(total, 1))) * 1.5
        let radius: Float = 0.4 + Float(index) * 0.05
        let height = Float(index) * 0.08 - Float(total) * 0.04

        let x = cos(angle) * radius
        let y = height
        let z = sin(angle) * radius - 0.8

        return SIMD3<Float>(x, y, z)
    }
}

// MARK: - VRSceneConfiguration

/// VRシーン設定
struct VRSceneConfiguration: Sendable {
    var displayMode: VRSceneService.DisplayMode = .grid
    var showAllEntries: Bool = true
    var maxVisibleEntries: Int = 50
    var enableAnimations: Bool = true
    var cardScale: Float = 1.0

    static let `default` = VRSceneConfiguration()
}
