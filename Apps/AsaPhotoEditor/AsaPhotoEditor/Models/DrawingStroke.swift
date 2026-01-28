import Foundation
import SwiftUI

// MARK: - DrawingStroke
/// 描画ストロークを管理する構造体
struct DrawingStroke: Identifiable, Codable, Equatable {
    // MARK: - Properties

    let id: UUID
    var points: [CGPoint]
    var colorHex: String
    var lineWidth: CGFloat
    var tool: DrawingTool
    var opacity: Double

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        points: [CGPoint] = [],
        colorHex: String = "#C68C53",
        lineWidth: CGFloat = 3.0,
        tool: DrawingTool = .pen,
        opacity: Double = 1.0
    ) {
        self.id = id
        self.points = points
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.tool = tool
        self.opacity = opacity
    }

    // MARK: - Computed Properties

    var color: Color {
        Color(hex: colorHex) ?? .black
    }

    var path: Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }

    var isEmpty: Bool {
        points.isEmpty
    }

    // MARK: - Methods

    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }

    mutating func updateColor(_ newColor: Color) {
        colorHex = newColor.toHex() ?? "#C68C53"
    }
}

// MARK: - DrawingTool
/// 描画ツールの列挙型
enum DrawingTool: String, CaseIterable, Identifiable, Codable {
    case pen = "ペン"
    case brush = "ブラシ"
    case highlighter = "蛍光ペン"
    case eraser = "消しゴム"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .pen: return "pencil.tip"
        case .brush: return "paintbrush"
        case .highlighter: return "highlighter"
        case .eraser: return "eraser"
        }
    }

    var defaultOpacity: Double {
        switch self {
        case .pen: return 1.0
        case .brush: return 0.8
        case .highlighter: return 0.4
        case .eraser: return 1.0
        }
    }

    var defaultLineWidth: CGFloat {
        switch self {
        case .pen: return 3.0
        case .brush: return 8.0
        case .highlighter: return 20.0
        case .eraser: return 20.0
        }
    }

    var lineWidthRange: ClosedRange<CGFloat> {
        switch self {
        case .pen: return 1.0...10.0
        case .brush: return 5.0...30.0
        case .highlighter: return 10.0...50.0
        case .eraser: return 10.0...50.0
        }
    }
}

// MARK: - DrawingLayer
/// 描画レイヤーを管理する構造体
struct DrawingLayer: Identifiable, Codable, Equatable {
    // MARK: - Properties

    let id: UUID
    var name: String
    var strokes: [DrawingStroke]
    var isVisible: Bool
    var opacity: Double
    var isLocked: Bool

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String = "レイヤー1",
        strokes: [DrawingStroke] = [],
        isVisible: Bool = true,
        opacity: Double = 1.0,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.strokes = strokes
        self.isVisible = isVisible
        self.opacity = opacity
        self.isLocked = isLocked
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        strokes.isEmpty
    }

    // MARK: - Methods

    mutating func addStroke(_ stroke: DrawingStroke) {
        strokes.append(stroke)
    }

    mutating func removeLastStroke() {
        if !strokes.isEmpty {
            strokes.removeLast()
        }
    }

    mutating func clear() {
        strokes.removeAll()
    }
}

// MARK: - CGPoint Codable
extension CGPoint: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
