import Foundation

// MARK: - PageCanvasViewModel

/// ページキャンバス画面のViewModel
/// 要素の追加・移動・リサイズ・削除・レイヤー操作を管理
@MainActor
@Observable
public final class PageCanvasViewModel {
    // MARK: - Properties

    public var page: StoryPage
    public var selectedElementId: UUID?
    public var errorMessage: String?

    // MARK: - Computed Properties

    /// 要素をzOrder順でソートして取得
    public var elements: [StoryElement] {
        page.sortedElements
    }

    /// 選択中の要素
    public var selectedElement: StoryElement? {
        guard let id = selectedElementId else { return nil }
        return page.elements.first { $0.id == id }
    }

    // MARK: - Init

    public init(page: StoryPage) {
        self.page = page
    }

    // MARK: - 要素追加

    /// 写真要素を追加
    public func addPhotoElement(imageData: Data) {
        let maxZ = page.elements.map(\.zOrder).max() ?? -1
        let element = StoryElement.photoElement(imageData: imageData, zOrder: maxZ + 1)
        element.page = page
        page.elements.append(element)
        selectedElementId = element.id
    }

    /// テキスト要素を追加
    public func addTextElement() {
        let maxZ = page.elements.map(\.zOrder).max() ?? -1
        let element = StoryElement.textElement(zOrder: maxZ + 1)
        element.page = page
        page.elements.append(element)
        selectedElementId = element.id
    }

    /// スタンプ要素を追加
    public func addStickerElement(name: String) {
        let maxZ = page.elements.map(\.zOrder).max() ?? -1
        let element = StoryElement.stickerElement(name: name, zOrder: maxZ + 1)
        element.page = page
        page.elements.append(element)
        selectedElementId = element.id
    }

    // MARK: - 要素操作

    /// 要素の位置を更新（正規化座標 0.0〜1.0）
    public func updateElementPosition(id: UUID, x: Double, y: Double) {
        guard let element = page.elements.first(where: { $0.id == id }) else { return }
        element.positionX = max(0, min(1, x))
        element.positionY = max(0, min(1, y))
    }

    /// 要素のサイズを更新（正規化サイズ）
    public func updateElementSize(id: UUID, width: Double, height: Double) {
        guard let element = page.elements.first(where: { $0.id == id }) else { return }
        element.width = max(0.05, min(1, width))
        element.height = max(0.05, min(1, height))
    }

    /// 要素の回転を更新（ラジアン）
    public func updateElementRotation(id: UUID, rotation: Double) {
        guard let element = page.elements.first(where: { $0.id == id }) else { return }
        element.rotation = rotation
    }

    /// 要素を削除
    public func deleteElement(id: UUID) {
        page.elements.removeAll { $0.id == id }
        if selectedElementId == id {
            selectedElementId = nil
        }
    }

    // MARK: - レイヤー操作

    /// 要素を最前面に移動
    public func bringToFront(id: UUID) {
        guard let element = page.elements.first(where: { $0.id == id }) else { return }
        let maxZ = page.elements.map(\.zOrder).max() ?? 0
        element.zOrder = maxZ + 1
    }

    /// 要素を最背面に移動
    public func sendToBack(id: UUID) {
        guard let element = page.elements.first(where: { $0.id == id }) else { return }
        let minZ = page.elements.map(\.zOrder).min() ?? 0
        element.zOrder = minZ - 1
    }

    /// 選択解除
    public func deselectAll() {
        selectedElementId = nil
    }

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }
}
