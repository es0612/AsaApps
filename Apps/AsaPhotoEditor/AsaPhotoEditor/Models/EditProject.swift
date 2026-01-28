import Foundation
import SwiftData

// MARK: - EditProject
/// 編集プロジェクトを管理するSwiftDataモデル
/// 非破壊編集のため、オリジナル画像と編集パラメータを分離して保存
@Model
final class EditProject {
    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// プロジェクト名
    var name: String

    /// オリジナル画像データ（非破壊編集用）
    @Attribute(.externalStorage)
    var originalImageData: Data?

    /// 画像調整パラメータ（JSON）
    var adjustmentData: Data?

    /// フィルター設定（JSON）
    var filterSettingsData: Data?

    /// クロップ設定（JSON）
    var cropSettingsData: Data?

    /// テキストレイヤー（JSON）
    var textLayersData: Data?

    /// 描画レイヤー（JSON）
    var drawingLayersData: Data?

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// サムネイル画像データ
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String = "無題のプロジェクト",
        originalImageData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.originalImageData = originalImageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// 画像調整パラメータを取得
    var adjustment: ImageAdjustment {
        get {
            guard let data = adjustmentData else { return .default }
            return (try? JSONDecoder().decode(ImageAdjustment.self, from: data)) ?? .default
        }
        set {
            adjustmentData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// フィルター設定を取得
    var filterSettings: FilterSettings {
        get {
            guard let data = filterSettingsData else { return .default }
            return (try? JSONDecoder().decode(FilterSettings.self, from: data)) ?? .default
        }
        set {
            filterSettingsData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// クロップ設定を取得
    var cropSettings: CropSettings {
        get {
            guard let data = cropSettingsData else { return .default }
            return (try? JSONDecoder().decode(CropSettings.self, from: data)) ?? .default
        }
        set {
            cropSettingsData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// テキストレイヤーを取得
    var textLayers: [TextLayer] {
        get {
            guard let data = textLayersData else { return [] }
            return (try? JSONDecoder().decode([TextLayer].self, from: data)) ?? []
        }
        set {
            textLayersData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// 描画レイヤーを取得
    var drawingLayers: [DrawingLayer] {
        get {
            guard let data = drawingLayersData else { return [] }
            return (try? JSONDecoder().decode([DrawingLayer].self, from: data)) ?? []
        }
        set {
            drawingLayersData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    /// 編集が行われているかどうか
    var hasEdits: Bool {
        !adjustment.isDefault ||
        !filterSettings.isDefault ||
        !cropSettings.isDefault ||
        !textLayers.isEmpty ||
        !drawingLayers.isEmpty
    }
}

// MARK: - EditProject + Convenience
extension EditProject {
    /// 編集状態を複製
    func duplicate(newName: String? = nil) -> EditProject {
        let project = EditProject(
            name: newName ?? "\(name) のコピー",
            originalImageData: originalImageData
        )
        project.adjustmentData = adjustmentData
        project.filterSettingsData = filterSettingsData
        project.cropSettingsData = cropSettingsData
        project.textLayersData = textLayersData
        project.drawingLayersData = drawingLayersData
        project.thumbnailData = thumbnailData
        return project
    }

    /// 編集をリセット
    func resetEdits() {
        adjustmentData = nil
        filterSettingsData = nil
        cropSettingsData = nil
        textLayersData = nil
        drawingLayersData = nil
        updatedAt = Date()
    }
}
