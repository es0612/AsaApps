import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 図形表示ノード

/// 図形パズル用の図形表示ノード（各種図形をCGPathで描画）
public class ShapeNode: SKShapeNode {

    // MARK: - ShapeType

    /// 図形の種類
    public enum ShapeType: String, CaseIterable, Sendable {
        case circle
        case triangle
        case square
        case rectangle
        case diamond
        case pentagon
        case hexagon
        case star

        /// 日本語名（子供向けひらがな表記）
        public var displayName: String {
            switch self {
            case .circle: return "まる"
            case .triangle: return "さんかく"
            case .square: return "しかく"
            case .rectangle: return "ながしかく"
            case .diamond: return "ひしがた"
            case .pentagon: return "ごかく"
            case .hexagon: return "ろっかく"
            case .star: return "ほし"
            }
        }
    }

    // MARK: - ファクトリメソッド

    /// 指定された図形タイプの ShapeNode を生成
    /// - Parameters:
    ///   - type: 図形タイプ
    ///   - size: 図形サイズ（幅・高さの基準値）
    ///   - color: 塗りつぶし色
    /// - Returns: 生成された ShapeNode
    public static func create(type: ShapeType, size: CGFloat, color: SKColor) -> ShapeNode {
        let path: CGPath

        switch type {
        case .circle:
            path = ShapeNode.createCirclePath(size: size)
        case .triangle:
            path = ShapeNode.createTrianglePath(size: size)
        case .square:
            path = ShapeNode.createSquarePath(size: size)
        case .rectangle:
            path = ShapeNode.createRectanglePath(size: size)
        case .diamond:
            path = ShapeNode.createDiamondPath(size: size)
        case .pentagon:
            path = ShapeNode.createPolygonPath(sides: 5, size: size)
        case .hexagon:
            path = ShapeNode.createPolygonPath(sides: 6, size: size)
        case .star:
            path = ShapeNode.createStarPath(size: size)
        }

        let node = ShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = darkenColor(color, by: 0.2)
        node.lineWidth = 3
        node.name = "shape_\(type.rawValue)"

        return node
    }

    // MARK: - パス生成

    /// 円のパスを生成
    private static func createCirclePath(size: CGFloat) -> CGPath {
        let radius = size / 2
        return CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: size, height: size),
            transform: nil
        )
    }

    /// 三角形のパスを生成
    private static func createTrianglePath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let halfSize = size / 2
        let height = size * 0.866 // sin(60度) * size

        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addLine(to: CGPoint(x: -halfSize, y: -height / 2))
        path.addLine(to: CGPoint(x: halfSize, y: -height / 2))
        path.closeSubpath()

        return path
    }

    /// 正方形のパスを生成
    private static func createSquarePath(size: CGFloat) -> CGPath {
        let halfSize = size / 2
        return CGPath(
            rect: CGRect(x: -halfSize, y: -halfSize, width: size, height: size),
            transform: nil
        )
    }

    /// 長方形のパスを生成
    private static func createRectanglePath(size: CGFloat) -> CGPath {
        let width = size * 1.4
        let height = size * 0.8
        return CGPath(
            rect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
            transform: nil
        )
    }

    /// ひし形のパスを生成
    private static func createDiamondPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let halfWidth = size / 2
        let halfHeight = size * 0.7

        path.move(to: CGPoint(x: 0, y: halfHeight))
        path.addLine(to: CGPoint(x: halfWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -halfHeight))
        path.addLine(to: CGPoint(x: -halfWidth, y: 0))
        path.closeSubpath()

        return path
    }

    /// 正多角形のパスを生成
    /// - Parameters:
    ///   - sides: 辺の数
    ///   - size: サイズ
    private static func createPolygonPath(sides: Int, size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let radius = size / 2
        let angleStep = (2 * CGFloat.pi) / CGFloat(sides)
        // 上向きに開始（-90度オフセット）
        let startAngle = -CGFloat.pi / 2

        for i in 0 ..< sides {
            let angle = startAngle + angleStep * CGFloat(i)
            let point = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }

    /// 星形のパスを生成
    private static func createStarPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        let angleStep = CGFloat.pi / CGFloat(points)
        let startAngle = -CGFloat.pi / 2

        for i in 0 ..< points * 2 {
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = startAngle + angleStep * CGFloat(i)
            let point = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }

    // MARK: - ユーティリティ

    /// 色を暗くする
    private static func darkenColor(_ color: SKColor, by amount: CGFloat) -> SKColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return SKColor(
            red: max(red - amount, 0),
            green: max(green - amount, 0),
            blue: max(blue - amount, 0),
            alpha: alpha
        )
    }
}
