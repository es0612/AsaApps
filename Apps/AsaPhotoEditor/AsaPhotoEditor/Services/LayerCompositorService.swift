import Foundation
import UIKit
import SwiftUI

// MARK: - LayerCompositorService
/// レイヤー合成サービス
/// 描画レイヤー、テキストレイヤーを画像に合成
actor LayerCompositorService {
    // MARK: - Public Methods

    /// すべてのレイヤーを画像に合成
    func compositeAllLayers(
        baseImage: UIImage,
        drawingLayers: [DrawingLayer],
        textLayers: [TextLayer]
    ) -> UIImage {
        let size = baseImage.size

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 1. ベース画像を描画
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext

            // 2. 描画レイヤーを合成（下から順に）
            for layer in drawingLayers.reversed() {
                guard layer.isVisible else { continue }

                cgContext.saveGState()
                cgContext.setAlpha(layer.opacity)

                for stroke in layer.strokes {
                    drawStroke(stroke, in: cgContext, imageSize: size)
                }

                cgContext.restoreGState()
            }

            // 3. テキストレイヤーを合成
            for textLayer in textLayers {
                drawTextLayer(textLayer, in: cgContext, imageSize: size)
            }
        }
    }

    /// 描画レイヤーのみを合成
    func compositeDrawingLayers(
        baseImage: UIImage,
        drawingLayers: [DrawingLayer]
    ) -> UIImage {
        let size = baseImage.size

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext

            for layer in drawingLayers.reversed() {
                guard layer.isVisible else { continue }

                cgContext.saveGState()
                cgContext.setAlpha(layer.opacity)

                for stroke in layer.strokes {
                    drawStroke(stroke, in: cgContext, imageSize: size)
                }

                cgContext.restoreGState()
            }
        }
    }

    /// テキストレイヤーのみを合成
    func compositeTextLayers(
        baseImage: UIImage,
        textLayers: [TextLayer]
    ) -> UIImage {
        let size = baseImage.size

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext

            for textLayer in textLayers {
                drawTextLayer(textLayer, in: cgContext, imageSize: size)
            }
        }
    }

    /// 透明な背景で描画レイヤーのみをレンダリング
    func renderDrawingLayersOnly(
        drawingLayers: [DrawingLayer],
        size: CGSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext

            for layer in drawingLayers.reversed() {
                guard layer.isVisible else { continue }

                cgContext.saveGState()
                cgContext.setAlpha(layer.opacity)

                for stroke in layer.strokes {
                    drawStroke(stroke, in: cgContext, imageSize: size)
                }

                cgContext.restoreGState()
            }
        }
    }

    // MARK: - Private Methods

    private func drawStroke(_ stroke: DrawingStroke, in context: CGContext, imageSize: CGSize) {
        guard stroke.points.count > 1 else { return }

        context.saveGState()

        // 正規化された座標を実際のピクセル座標に変換
        let scaledPoints = stroke.points.map { point in
            CGPoint(x: point.x * imageSize.width, y: point.y * imageSize.height)
        }

        context.setLineWidth(stroke.lineWidth * (imageSize.width / 400)) // スケール調整
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch stroke.tool {
        case .pen:
            context.setStrokeColor(UIColor(stroke.color).cgColor)
            context.setAlpha(stroke.opacity)

        case .brush:
            context.setStrokeColor(UIColor(stroke.color).cgColor)
            context.setAlpha(stroke.opacity * 0.8)

        case .highlighter:
            context.setStrokeColor(UIColor(stroke.color).cgColor)
            context.setAlpha(stroke.opacity * 0.4)
            context.setBlendMode(.multiply)

        case .eraser:
            context.setStrokeColor(UIColor.white.cgColor)
            context.setBlendMode(.clear)
        }

        context.beginPath()
        context.move(to: scaledPoints[0])

        for i in 1..<scaledPoints.count {
            context.addLine(to: scaledPoints[i])
        }

        context.strokePath()
        context.restoreGState()
    }

    private func drawTextLayer(_ textLayer: TextLayer, in context: CGContext, imageSize: CGSize) {
        context.saveGState()

        // 位置を計算（正規化座標から実座標へ）
        let x = textLayer.position.x * imageSize.width
        let y = textLayer.position.y * imageSize.height

        // フォントサイズをスケール
        let scaledFontSize = textLayer.fontSize * (imageSize.width / 400)
        let font = UIFont(name: textLayer.fontName, size: scaledFontSize)
            ?? UIFont.systemFont(ofSize: scaledFontSize, weight: .semibold)

        // テキスト属性
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(textLayer.color).withAlphaComponent(textLayer.opacity),
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: textLayer.text, attributes: attributes)
        let textSize = attributedString.size()

        // 回転を適用
        context.translateBy(x: x, y: y)
        context.rotate(by: textLayer.rotation)

        // テキストを中央揃えで描画
        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        attributedString.draw(in: textRect)

        context.restoreGState()
    }
}
