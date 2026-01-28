import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import AsaPhotoEditor

// MARK: - DrawingStroke Tests
@Suite("DrawingStroke Tests")
struct DrawingStrokeTests {
    // MARK: - Default Values

    @Test("デフォルト値の確認")
    func testDefaultValues() {
        let stroke = DrawingStroke()

        #expect(stroke.points.isEmpty)
        #expect(stroke.colorHex == "#C68C53")
        #expect(stroke.lineWidth == 3.0)
        #expect(stroke.tool == .pen)
        #expect(stroke.opacity == 1.0)
        #expect(stroke.isEmpty == true)
    }

    // MARK: - Point Operations

    @Test("ポイントの追加")
    func testAddPoint() {
        var stroke = DrawingStroke()

        stroke.addPoint(CGPoint(x: 10, y: 20))
        stroke.addPoint(CGPoint(x: 30, y: 40))

        #expect(stroke.points.count == 2)
        #expect(stroke.isEmpty == false)
    }

    // MARK: - Path Generation

    @Test("ポイントが少ないと空のパス")
    func testEmptyPath() {
        var stroke = DrawingStroke()
        stroke.addPoint(CGPoint(x: 10, y: 20))

        #expect(stroke.path.isEmpty)
    }

    @Test("複数ポイントでパスが生成される")
    func testPathGeneration() {
        var stroke = DrawingStroke()
        stroke.addPoint(CGPoint(x: 10, y: 20))
        stroke.addPoint(CGPoint(x: 30, y: 40))
        stroke.addPoint(CGPoint(x: 50, y: 60))

        #expect(!stroke.path.isEmpty)
    }

    // MARK: - Color

    @Test("カラーの更新")
    func testUpdateColor() {
        var stroke = DrawingStroke()
        // 明示的なRGB値のカラーを使用（システムカラーはプラットフォーム依存のため）
        let customRed = Color(red: 1.0, green: 0.0, blue: 0.0)
        stroke.updateColor(customRed)

        #expect(stroke.colorHex == "#FF0000")
    }

    // MARK: - Codable

    @Test("Codableのテスト")
    func testCodable() throws {
        var original = DrawingStroke()
        original.addPoint(CGPoint(x: 10, y: 20))
        original.addPoint(CGPoint(x: 30, y: 40))
        original.lineWidth = 5.0
        original.tool = .highlighter

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DrawingStroke.self, from: data)

        #expect(decoded.points.count == original.points.count)
        #expect(decoded.lineWidth == original.lineWidth)
        #expect(decoded.tool == original.tool)
    }
}

// MARK: - DrawingTool Tests
@Suite("DrawingTool Tests")
struct DrawingToolTests {
    @Test("すべてのツールにアイコン名がある")
    func testIconNames() {
        for tool in DrawingTool.allCases {
            #expect(!tool.iconName.isEmpty)
        }
    }

    @Test("デフォルト透明度")
    func testDefaultOpacity() {
        #expect(DrawingTool.pen.defaultOpacity == 1.0)
        #expect(DrawingTool.brush.defaultOpacity == 0.8)
        #expect(DrawingTool.highlighter.defaultOpacity == 0.4)
        #expect(DrawingTool.eraser.defaultOpacity == 1.0)
    }

    @Test("デフォルト線幅")
    func testDefaultLineWidth() {
        #expect(DrawingTool.pen.defaultLineWidth == 3.0)
        #expect(DrawingTool.brush.defaultLineWidth == 8.0)
        #expect(DrawingTool.highlighter.defaultLineWidth == 20.0)
        #expect(DrawingTool.eraser.defaultLineWidth == 20.0)
    }

    @Test("線幅の範囲")
    func testLineWidthRange() {
        let penRange = DrawingTool.pen.lineWidthRange
        #expect(penRange.lowerBound == 1.0)
        #expect(penRange.upperBound == 10.0)
    }
}

// MARK: - DrawingLayer Tests
@Suite("DrawingLayer Tests")
struct DrawingLayerTests {
    @Test("デフォルト値の確認")
    func testDefaultValues() {
        let layer = DrawingLayer()

        #expect(layer.name == "レイヤー1")
        #expect(layer.strokes.isEmpty)
        #expect(layer.isVisible == true)
        #expect(layer.opacity == 1.0)
        #expect(layer.isLocked == false)
        #expect(layer.isEmpty == true)
    }

    @Test("ストロークの追加")
    func testAddStroke() {
        var layer = DrawingLayer()
        var stroke = DrawingStroke()
        stroke.addPoint(CGPoint(x: 10, y: 20))

        layer.addStroke(stroke)

        #expect(layer.strokes.count == 1)
        #expect(layer.isEmpty == false)
    }

    @Test("最後のストロークを削除")
    func testRemoveLastStroke() {
        var layer = DrawingLayer()
        layer.addStroke(DrawingStroke())
        layer.addStroke(DrawingStroke())

        layer.removeLastStroke()

        #expect(layer.strokes.count == 1)
    }

    @Test("空のレイヤーでremoveLastStrokeしても安全")
    func testRemoveLastStrokeOnEmpty() {
        var layer = DrawingLayer()
        layer.removeLastStroke()

        #expect(layer.strokes.isEmpty)
    }

    @Test("クリア")
    func testClear() {
        var layer = DrawingLayer()
        layer.addStroke(DrawingStroke())
        layer.addStroke(DrawingStroke())

        layer.clear()

        #expect(layer.isEmpty == true)
    }

    @Test("Codableのテスト")
    func testCodable() throws {
        var original = DrawingLayer(name: "テストレイヤー")
        original.isVisible = false
        original.opacity = 0.5

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DrawingLayer.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.isVisible == original.isVisible)
        #expect(decoded.opacity == original.opacity)
    }
}
