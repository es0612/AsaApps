//
//  DrawingCanvasView.swift
//  AsaMultiplayerGame
//
//  描画キャンバスコンポーネント
//

import SwiftUI

/// 描画キャンバスビュー
///
/// Canvas APIとDragGestureを使用してリアルタイム描画を実現します。
struct DrawingCanvasView: View {
    // MARK: - Properties

    /// キャンバスデータ（完了したストローク）
    let canvas: DrawingCanvas

    /// 現在描画中のストローク
    let currentStroke: DrawingStroke?

    /// 描画可能かどうか
    let isDrawingEnabled: Bool

    /// 描画開始時のコールバック
    var onDrawingStarted: ((CGPoint) -> Void)?

    /// 描画継続時のコールバック
    var onDrawingContinued: ((CGPoint) -> Void)?

    /// 描画終了時のコールバック
    var onDrawingEnded: (() -> Void)?

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // 背景を白で塗りつぶし
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.white)
                )

                // 完了したストロークを描画
                for stroke in canvas.strokes {
                    drawStroke(stroke, in: &context)
                }

                // 現在描画中のストロークを描画
                if let current = currentStroke {
                    drawStroke(current, in: &context)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isDrawingEnabled else { return }

                        let point = value.location
                        // 境界内に収める
                        let clampedPoint = CGPoint(
                            x: max(0, min(geometry.size.width, point.x)),
                            y: max(0, min(geometry.size.height, point.y))
                        )

                        if value.startLocation == value.location {
                            onDrawingStarted?(clampedPoint)
                        } else {
                            onDrawingContinued?(clampedPoint)
                        }
                    }
                    .onEnded { _ in
                        guard isDrawingEnabled else { return }
                        onDrawingEnded?()
                    }
            )
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AsaMutedSage").opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }

    // MARK: - Drawing Methods

    private func drawStroke(_ stroke: DrawingStroke, in context: inout GraphicsContext) {
        guard stroke.points.count >= 2 else {
            // 点が1つだけの場合は小さな円を描画
            if let point = stroke.points.first {
                let rect = CGRect(
                    x: point.x - stroke.lineWidth / 2,
                    y: point.y - stroke.lineWidth / 2,
                    width: stroke.lineWidth,
                    height: stroke.lineWidth
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(stroke.color.color)
                )
            }
            return
        }

        var path = Path()
        let points = stroke.cgPoints

        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
        } else {
            // スムーズな曲線を描画
            for i in 1..<points.count {
                let mid = CGPoint(
                    x: (points[i - 1].x + points[i].x) / 2,
                    y: (points[i - 1].y + points[i].y) / 2
                )

                if i == 1 {
                    path.addLine(to: mid)
                } else {
                    path.addQuadCurve(to: mid, control: points[i - 1])
                }
            }

            path.addLine(to: points.last!)
        }

        context.stroke(
            path,
            with: .color(stroke.color.color),
            style: StrokeStyle(
                lineWidth: stroke.lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

// MARK: - Preview

#Preview {
    let stroke1 = DrawingStroke(
        points: [
            StrokePoint(x: 50, y: 50),
            StrokePoint(x: 100, y: 100),
            StrokePoint(x: 150, y: 80)
        ],
        color: .black,
        lineWidth: 4
    )

    let stroke2 = DrawingStroke(
        points: [
            StrokePoint(x: 200, y: 50),
            StrokePoint(x: 250, y: 150)
        ],
        color: .red,
        lineWidth: 8
    )

    let canvas = DrawingCanvas(strokes: [stroke1, stroke2])

    return DrawingCanvasView(
        canvas: canvas,
        currentStroke: nil,
        isDrawingEnabled: true
    )
    .frame(width: 300, height: 300)
    .padding()
}
