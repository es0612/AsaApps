import Foundation
import SwiftData

// MARK: - StoryElement

/// ページ上の要素を管理するSwiftDataモデル（単一テーブル設計）
/// photo/text/sticker/drawing の全種別を1つのモデルで表現
@Model
public final class StoryElement {
    // MARK: - 共通プロパティ

    /// 一意識別子
    public var id: UUID

    /// 要素種別（rawValue保存）
    public var typeRawValue: String

    /// 正規化X座標 (0.0〜1.0)
    public var positionX: Double

    /// 正規化Y座標 (0.0〜1.0)
    public var positionY: Double

    /// 正規化幅
    public var width: Double

    /// 正規化高さ
    public var height: Double

    /// 回転角（ラジアン）
    public var rotation: Double

    /// レイヤー順序
    public var zOrder: Int

    /// 不透明度
    public var opacity: Double

    // MARK: - テキスト要素用プロパティ

    /// テキスト内容
    public var text: String?

    /// フォント名
    public var fontName: String?

    /// フォントサイズ
    public var fontSize: Double?

    /// テキスト色HEX
    public var textColorHex: String?

    // MARK: - 写真要素用プロパティ

    /// 画像データ
    @Attribute(.externalStorage)
    public var imageData: Data?

    /// キャプションテキスト
    public var captionText: String?

    // MARK: - スタンプ要素用プロパティ

    /// SF Symbol名
    public var stickerName: String?

    // MARK: - 手描き要素用プロパティ

    /// PencilKit描画データ
    public var drawingData: Data?

    // MARK: - リレーション

    /// 親ページ
    public var page: StoryPage?

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        type: ElementType = .photo,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        width: Double = 0.8,
        height: Double = 0.6,
        rotation: Double = 0,
        zOrder: Int = 0,
        opacity: Double = 1.0
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.rotation = rotation
        self.zOrder = zOrder
        self.opacity = opacity
    }

    // MARK: - Computed Properties

    /// 要素種別の型変換
    public var elementType: ElementType {
        get { ElementType(rawValue: typeRawValue) ?? .photo }
        set { typeRawValue = newValue.rawValue }
    }

    /// 正規化座標をCGPointで取得
    public var position: (x: Double, y: Double) {
        (x: positionX, y: positionY)
    }

    /// 正規化サイズをタプルで取得
    public var size: (width: Double, height: Double) {
        (width: width, height: height)
    }
}

// MARK: - StoryElement + Factory

public extension StoryElement {
    /// 写真要素を作成
    static func photoElement(
        imageData: Data,
        caption: String? = nil,
        zOrder: Int = 0
    ) -> StoryElement {
        let element = StoryElement(type: .photo, zOrder: zOrder)
        element.imageData = imageData
        element.captionText = caption
        return element
    }

    /// テキスト要素を作成
    static func textElement(
        text: String = "テキスト",
        fontName: String = "HiraginoSans-W6",
        fontSize: Double = 24,
        colorHex: String = "#333333",
        zOrder: Int = 0
    ) -> StoryElement {
        let element = StoryElement(
            type: .text,
            width: 0.6,
            height: 0.15,
            zOrder: zOrder
        )
        element.text = text
        element.fontName = fontName
        element.fontSize = fontSize
        element.textColorHex = colorHex
        return element
    }

    /// スタンプ要素を作成
    static func stickerElement(
        name: String,
        zOrder: Int = 0
    ) -> StoryElement {
        let element = StoryElement(
            type: .sticker,
            width: 0.15,
            height: 0.15,
            zOrder: zOrder
        )
        element.stickerName = name
        return element
    }

    /// 手描き要素を作成
    static func drawingElement(
        drawingData: Data,
        zOrder: Int = 0
    ) -> StoryElement {
        let element = StoryElement(type: .drawing, zOrder: zOrder)
        element.drawingData = drawingData
        return element
    }
}
