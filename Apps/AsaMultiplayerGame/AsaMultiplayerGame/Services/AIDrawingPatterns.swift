//
//  AIDrawingPatterns.swift
//  AsaMultiplayerGame
//
//  AIプレイヤーの描画パターン定義
//

import Foundation

/// AIプレイヤーの描画パターンを提供するサービス
///
/// 各お題に対応する事前定義パターンと、未知のお題用の汎用パターンを持ちます。
/// 座標は300x300キャンバスを前提に定義されています。
struct AIDrawingPatterns: Sendable {

    // MARK: - Public API

    /// 指定されたお題に対応する描画ストロークを生成
    /// - Parameter word: お題の文字列
    /// - Returns: 段階的に追加する描画ストローク配列
    static func generateStrokes(for word: String) -> [DrawingStroke] {
        if let pattern = knownPatterns[word] {
            return pattern()
        }
        return genericPattern()
    }

    // MARK: - Known Patterns

    private static let knownPatterns: [String: @Sendable () -> [DrawingStroke]] = [
        "りんご": applePattern,
        "ねこ": catPattern,
        "いぬ": dogPattern,
        "たいよう": sunPattern,
        "いえ": housePattern,
        "くるま": carPattern,
        "はな": flowerPattern,
        "き": treePattern,
        "くも": cloudPattern,
        "やま": mountainPattern,
        "さかな": fishPattern,
        "ほし": starPattern,
        "かさ": umbrellaPattern,
        "つき": moonPattern,
    ]

    // MARK: - Pattern Definitions

    /// りんご: 丸い本体 + 茎 + 葉
    private static func applePattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 本体（赤い丸）
        strokes.append(makeCircleStroke(cx: 150, cy: 160, radius: 70, color: .red))

        // 茎（茶色の短い線）
        strokes.append(makeLineStroke(
            from: CGPoint(x: 150, y: 90), to: CGPoint(x: 145, y: 65), color: .brown, lineWidth: 3
        ))

        // 葉（緑の曲線）
        strokes.append(makeStroke(points: [
            CGPoint(x: 150, y: 78), CGPoint(x: 165, y: 68),
            CGPoint(x: 180, y: 72), CGPoint(x: 170, y: 80),
        ], color: .green, lineWidth: 3))

        return strokes
    }

    /// ねこ: 丸い顔 + 耳 + 目 + ひげ + 体
    private static func catPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 顔（丸）
        strokes.append(makeCircleStroke(cx: 150, cy: 130, radius: 50, color: .black))

        // 左耳
        strokes.append(makeStroke(points: [
            CGPoint(x: 112, y: 90), CGPoint(x: 105, y: 55), CGPoint(x: 130, y: 85),
        ], color: .black))

        // 右耳
        strokes.append(makeStroke(points: [
            CGPoint(x: 188, y: 90), CGPoint(x: 195, y: 55), CGPoint(x: 170, y: 85),
        ], color: .black))

        // 左目
        strokes.append(makeCircleStroke(cx: 132, cy: 125, radius: 6, color: .black, lineWidth: 3))

        // 右目
        strokes.append(makeCircleStroke(cx: 168, cy: 125, radius: 6, color: .black, lineWidth: 3))

        // 口（小さいW字）
        strokes.append(makeStroke(points: [
            CGPoint(x: 140, y: 148), CGPoint(x: 150, y: 155), CGPoint(x: 160, y: 148),
        ], color: .black, lineWidth: 2))

        // 左ひげ
        strokes.append(makeLineStroke(
            from: CGPoint(x: 105, y: 138), to: CGPoint(x: 135, y: 142), color: .black, lineWidth: 2
        ))

        // 右ひげ
        strokes.append(makeLineStroke(
            from: CGPoint(x: 165, y: 142), to: CGPoint(x: 195, y: 138), color: .black, lineWidth: 2
        ))

        // 体（楕円風）
        strokes.append(makeStroke(points: [
            CGPoint(x: 120, y: 175), CGPoint(x: 110, y: 210),
            CGPoint(x: 120, y: 245), CGPoint(x: 150, y: 255),
            CGPoint(x: 180, y: 245), CGPoint(x: 190, y: 210),
            CGPoint(x: 180, y: 175),
        ], color: .black))

        return strokes
    }

    /// いぬ: 顔 + 耳(垂れ) + 目 + 鼻 + 体
    private static func dogPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 顔
        strokes.append(makeCircleStroke(cx: 150, cy: 120, radius: 45, color: .brown))

        // 左垂れ耳
        strokes.append(makeStroke(points: [
            CGPoint(x: 110, y: 100), CGPoint(x: 90, y: 120), CGPoint(x: 95, y: 155),
        ], color: .brown))

        // 右垂れ耳
        strokes.append(makeStroke(points: [
            CGPoint(x: 190, y: 100), CGPoint(x: 210, y: 120), CGPoint(x: 205, y: 155),
        ], color: .brown))

        // 目
        strokes.append(makeCircleStroke(cx: 135, cy: 115, radius: 5, color: .black, lineWidth: 3))
        strokes.append(makeCircleStroke(cx: 165, cy: 115, radius: 5, color: .black, lineWidth: 3))

        // 鼻
        strokes.append(makeCircleStroke(cx: 150, cy: 135, radius: 7, color: .black, lineWidth: 4))

        // 体
        strokes.append(makeStroke(points: [
            CGPoint(x: 120, y: 165), CGPoint(x: 110, y: 200),
            CGPoint(x: 115, y: 240), CGPoint(x: 150, y: 250),
            CGPoint(x: 185, y: 240), CGPoint(x: 190, y: 200),
            CGPoint(x: 180, y: 165),
        ], color: .brown))

        return strokes
    }

    /// たいよう: 黄色い丸 + 放射線
    private static func sunPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 本体（黄色い丸）
        strokes.append(makeCircleStroke(cx: 150, cy: 150, radius: 45, color: .orange, lineWidth: 5))

        // 放射線 8本
        let rayLength: CGFloat = 35
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let innerR: CGFloat = 50
            let startX = 150 + cos(angle) * innerR
            let startY = 150 + sin(angle) * innerR
            let endX = 150 + cos(angle) * (innerR + rayLength)
            let endY = 150 + sin(angle) * (innerR + rayLength)
            strokes.append(makeLineStroke(
                from: CGPoint(x: startX, y: startY),
                to: CGPoint(x: endX, y: endY),
                color: .yellow, lineWidth: 4
            ))
        }

        return strokes
    }

    /// いえ: 四角い壁 + 三角屋根 + ドア + 窓
    private static func housePattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 壁（四角）
        strokes.append(makeStroke(points: [
            CGPoint(x: 80, y: 160), CGPoint(x: 220, y: 160),
            CGPoint(x: 220, y: 260), CGPoint(x: 80, y: 260),
            CGPoint(x: 80, y: 160),
        ], color: .brown))

        // 屋根（三角）
        strokes.append(makeStroke(points: [
            CGPoint(x: 65, y: 160), CGPoint(x: 150, y: 80), CGPoint(x: 235, y: 160),
        ], color: .red, lineWidth: 5))

        // ドア
        strokes.append(makeStroke(points: [
            CGPoint(x: 135, y: 260), CGPoint(x: 135, y: 210),
            CGPoint(x: 165, y: 210), CGPoint(x: 165, y: 260),
        ], color: .brown))

        // 窓（左）
        strokes.append(makeStroke(points: [
            CGPoint(x: 95, y: 185), CGPoint(x: 120, y: 185),
            CGPoint(x: 120, y: 210), CGPoint(x: 95, y: 210),
            CGPoint(x: 95, y: 185),
        ], color: .blue, lineWidth: 2))

        // 窓（右）
        strokes.append(makeStroke(points: [
            CGPoint(x: 180, y: 185), CGPoint(x: 205, y: 185),
            CGPoint(x: 205, y: 210), CGPoint(x: 180, y: 210),
            CGPoint(x: 180, y: 185),
        ], color: .blue, lineWidth: 2))

        return strokes
    }

    /// くるま: ボディ + タイヤ + 窓
    private static func carPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // ボディ下部
        strokes.append(makeStroke(points: [
            CGPoint(x: 50, y: 180), CGPoint(x: 250, y: 180),
            CGPoint(x: 250, y: 210), CGPoint(x: 50, y: 210),
            CGPoint(x: 50, y: 180),
        ], color: .red))

        // ボディ上部（台形）
        strokes.append(makeStroke(points: [
            CGPoint(x: 90, y: 180), CGPoint(x: 120, y: 140),
            CGPoint(x: 210, y: 140), CGPoint(x: 230, y: 180),
        ], color: .red))

        // 左タイヤ
        strokes.append(makeCircleStroke(cx: 100, cy: 215, radius: 18, color: .black, lineWidth: 5))

        // 右タイヤ
        strokes.append(makeCircleStroke(cx: 200, cy: 215, radius: 18, color: .black, lineWidth: 5))

        // 窓
        strokes.append(makeStroke(points: [
            CGPoint(x: 130, y: 175), CGPoint(x: 135, y: 148),
            CGPoint(x: 165, y: 148), CGPoint(x: 165, y: 175),
        ], color: .blue, lineWidth: 2))

        return strokes
    }

    /// はな: 花びら + 茎 + 葉
    private static func flowerPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 花びら（5枚の円）
        let petalRadius: CGFloat = 20
        for i in 0..<5 {
            let angle = Double(i) * 2 * .pi / 5 - .pi / 2
            let cx = 150 + cos(angle) * 25
            let cy = 120 + sin(angle) * 25
            strokes.append(makeCircleStroke(cx: cx, cy: cy, radius: petalRadius, color: .red, lineWidth: 3))
        }

        // 花の中心
        strokes.append(makeCircleStroke(cx: 150, cy: 120, radius: 12, color: .yellow, lineWidth: 4))

        // 茎
        strokes.append(makeLineStroke(
            from: CGPoint(x: 150, y: 145), to: CGPoint(x: 150, y: 260), color: .green, lineWidth: 4
        ))

        // 葉
        strokes.append(makeStroke(points: [
            CGPoint(x: 150, y: 200), CGPoint(x: 180, y: 185),
            CGPoint(x: 195, y: 195), CGPoint(x: 170, y: 210),
        ], color: .green, lineWidth: 3))

        return strokes
    }

    /// き: 幹 + 枝葉（丸い葉群）
    private static func treePattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 幹
        strokes.append(makeStroke(points: [
            CGPoint(x: 140, y: 260), CGPoint(x: 140, y: 150),
            CGPoint(x: 160, y: 150), CGPoint(x: 160, y: 260),
        ], color: .brown, lineWidth: 5))

        // 葉（大きい丸3つ）
        strokes.append(makeCircleStroke(cx: 150, cy: 110, radius: 50, color: .green, lineWidth: 5))
        strokes.append(makeCircleStroke(cx: 115, cy: 135, radius: 35, color: .green, lineWidth: 4))
        strokes.append(makeCircleStroke(cx: 185, cy: 135, radius: 35, color: .green, lineWidth: 4))

        return strokes
    }

    /// くも: 重なった丸
    private static func cloudPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        strokes.append(makeCircleStroke(cx: 120, cy: 150, radius: 35, color: .blue, lineWidth: 3))
        strokes.append(makeCircleStroke(cx: 155, cy: 135, radius: 40, color: .blue, lineWidth: 3))
        strokes.append(makeCircleStroke(cx: 190, cy: 150, radius: 35, color: .blue, lineWidth: 3))
        strokes.append(makeCircleStroke(cx: 140, cy: 165, radius: 30, color: .blue, lineWidth: 3))
        strokes.append(makeCircleStroke(cx: 170, cy: 165, radius: 30, color: .blue, lineWidth: 3))

        return strokes
    }

    /// やま: 三角形 + 雪帽子
    private static func mountainPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 山本体
        strokes.append(makeStroke(points: [
            CGPoint(x: 40, y: 250), CGPoint(x: 150, y: 80), CGPoint(x: 260, y: 250),
        ], color: .green, lineWidth: 5))

        // 雪帽子
        strokes.append(makeStroke(points: [
            CGPoint(x: 125, y: 120), CGPoint(x: 150, y: 80), CGPoint(x: 175, y: 120),
            CGPoint(x: 160, y: 115), CGPoint(x: 140, y: 125), CGPoint(x: 125, y: 120),
        ], color: .white, lineWidth: 4))

        return strokes
    }

    /// さかな: 楕円の体 + 尾 + 目
    private static func fishPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 体（楕円風）
        strokes.append(makeStroke(points: [
            CGPoint(x: 80, y: 150), CGPoint(x: 110, y: 120),
            CGPoint(x: 160, y: 110), CGPoint(x: 200, y: 120),
            CGPoint(x: 220, y: 150), CGPoint(x: 200, y: 180),
            CGPoint(x: 160, y: 190), CGPoint(x: 110, y: 180),
            CGPoint(x: 80, y: 150),
        ], color: .blue))

        // 尾
        strokes.append(makeStroke(points: [
            CGPoint(x: 220, y: 150), CGPoint(x: 260, y: 120),
            CGPoint(x: 255, y: 150), CGPoint(x: 260, y: 180),
            CGPoint(x: 220, y: 150),
        ], color: .blue))

        // 目
        strokes.append(makeCircleStroke(cx: 120, cy: 140, radius: 8, color: .black, lineWidth: 3))

        return strokes
    }

    /// ほし: 星形の5つの頂点
    private static func starPattern() -> [DrawingStroke] {
        var points: [CGPoint] = []

        for i in 0..<5 {
            // 外側の頂点
            let outerAngle = Double(i) * 2 * .pi / 5 - .pi / 2
            points.append(CGPoint(
                x: 150 + cos(outerAngle) * 70,
                y: 150 + sin(outerAngle) * 70
            ))
            // 内側の頂点
            let innerAngle = outerAngle + .pi / 5
            points.append(CGPoint(
                x: 150 + cos(innerAngle) * 30,
                y: 150 + sin(innerAngle) * 30
            ))
        }
        points.append(points[0]) // 閉じる

        return [makeStroke(points: points, color: .yellow, lineWidth: 4)]
    }

    /// かさ: 半円の傘部分 + 柄
    private static func umbrellaPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 傘部分（半円弧）
        var arcPoints: [CGPoint] = []
        for i in stride(from: 0, through: 180, by: 10) {
            let angle = Double(i) * .pi / 180
            arcPoints.append(CGPoint(
                x: 150 - cos(angle) * 80,
                y: 130 - sin(angle) * 60
            ))
        }
        strokes.append(makeStroke(points: arcPoints, color: .blue, lineWidth: 4))

        // 柄（直線）
        strokes.append(makeLineStroke(
            from: CGPoint(x: 150, y: 130), to: CGPoint(x: 150, y: 240), color: .brown, lineWidth: 3
        ))

        // 持ち手（J字フック）
        strokes.append(makeStroke(points: [
            CGPoint(x: 150, y: 240), CGPoint(x: 145, y: 255),
            CGPoint(x: 135, y: 260), CGPoint(x: 125, y: 255),
        ], color: .brown, lineWidth: 3))

        return strokes
    }

    /// つき: 三日月形
    private static func moonPattern() -> [DrawingStroke] {
        var strokes: [DrawingStroke] = []

        // 外側の弧
        var outerArc: [CGPoint] = []
        for i in stride(from: -90, through: 90, by: 10) {
            let angle = Double(i) * .pi / 180
            outerArc.append(CGPoint(
                x: 150 + cos(angle) * 65,
                y: 150 + sin(angle) * 65
            ))
        }
        strokes.append(makeStroke(points: outerArc, color: .yellow, lineWidth: 4))

        // 内側の弧（くぼみ）
        var innerArc: [CGPoint] = []
        for i in stride(from: 90, through: -90, by: -10) {
            let angle = Double(i) * .pi / 180
            innerArc.append(CGPoint(
                x: 170 + cos(angle) * 50,
                y: 150 + sin(angle) * 50
            ))
        }
        strokes.append(makeStroke(points: innerArc, color: .yellow, lineWidth: 4))

        return strokes
    }

    // MARK: - Generic Pattern

    /// 未知のお題用の汎用パターン（ランダムな幾何学図形）
    private static func genericPattern() -> [DrawingStroke] {
        let patterns: [() -> [DrawingStroke]] = [
            genericCirclesPattern,
            genericZigzagPattern,
            genericSquarePattern,
        ]
        return patterns.randomElement()?() ?? genericCirclesPattern()
    }

    /// 汎用: 複数の丸
    private static func genericCirclesPattern() -> [DrawingStroke] {
        [
            makeCircleStroke(cx: 150, cy: 130, radius: 50, color: .black),
            makeCircleStroke(cx: 130, cy: 115, radius: 8, color: .black, lineWidth: 3),
            makeCircleStroke(cx: 170, cy: 115, radius: 8, color: .black, lineWidth: 3),
            makeStroke(points: [
                CGPoint(x: 130, y: 150), CGPoint(x: 150, y: 160), CGPoint(x: 170, y: 150),
            ], color: .black, lineWidth: 2),
        ]
    }

    /// 汎用: ジグザグ
    private static func genericZigzagPattern() -> [DrawingStroke] {
        var points: [CGPoint] = []
        for i in 0..<8 {
            let x: CGFloat = 60 + CGFloat(i) * 30
            let y: CGFloat = (i % 2 == 0) ? 120 : 200
            points.append(CGPoint(x: x, y: y))
        }
        return [
            makeStroke(points: points, color: .blue, lineWidth: 4),
            makeCircleStroke(cx: 150, cy: 160, radius: 40, color: .red, lineWidth: 3),
        ]
    }

    /// 汎用: 四角形と線
    private static func genericSquarePattern() -> [DrawingStroke] {
        [
            makeStroke(points: [
                CGPoint(x: 90, y: 90), CGPoint(x: 210, y: 90),
                CGPoint(x: 210, y: 210), CGPoint(x: 90, y: 210),
                CGPoint(x: 90, y: 90),
            ], color: .black),
            makeLineStroke(from: CGPoint(x: 90, y: 90), to: CGPoint(x: 210, y: 210), color: .red),
            makeLineStroke(from: CGPoint(x: 210, y: 90), to: CGPoint(x: 90, y: 210), color: .red),
        ]
    }

    // MARK: - Stroke Helpers

    /// 点群からストロークを生成
    private static func makeStroke(
        points: [CGPoint],
        color: StrokeColor = .black,
        lineWidth: CGFloat = 4.0
    ) -> DrawingStroke {
        DrawingStroke(
            points: points.map { StrokePoint($0) },
            color: color,
            lineWidth: lineWidth
        )
    }

    /// 2点間の直線ストロークを生成
    private static func makeLineStroke(
        from start: CGPoint,
        to end: CGPoint,
        color: StrokeColor = .black,
        lineWidth: CGFloat = 4.0
    ) -> DrawingStroke {
        makeStroke(points: [start, end], color: color, lineWidth: lineWidth)
    }

    /// 円のストロークを生成（16分割の多角形で近似）
    private static func makeCircleStroke(
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        color: StrokeColor = .black,
        lineWidth: CGFloat = 4.0
    ) -> DrawingStroke {
        var points: [CGPoint] = []
        let segments = 16
        for i in 0...segments {
            let angle = Double(i) * 2 * .pi / Double(segments)
            points.append(CGPoint(
                x: cx + cos(angle) * radius,
                y: cy + sin(angle) * radius
            ))
        }
        return makeStroke(points: points, color: color, lineWidth: lineWidth)
    }
}
