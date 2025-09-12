//
//  CanvasLayerView.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

struct CanvasLayerView: View {
    @Bindable var viewModel: DrawingProViewModel
    
    var body: some View {
        Canvas { context, size in
            // 各レイヤーを下から順に描画
            for layer in viewModel.layers.reversed() {
                // 非表示のレイヤーはスキップ
                guard layer.isVisible else { continue }
                
                // レイヤーのopacityを適用
                context.opacity = layer.opacity
                
                // レイヤー内の全ストロークを描画
                for stroke in layer.strokes {
                    drawStroke(stroke, in: context)
                }
            }
            
            // 現在描画中のストローク
            if let currentStroke = viewModel.currentStroke {
                drawStroke(currentStroke, in: context)
            }
        }
        .frame(minWidth: 200, minHeight: 300)
        .background(Color.white)
        .cornerRadius(10)
        .gesture(drawingGesture)
    }
    
    // MARK: - Drawing Methods
    
    private func drawStroke(_ stroke: DrawingStroke, in context: GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        
        var path = Path()
        path.move(to: stroke.points[0])
        
        for i in 1..<stroke.points.count {
            path.addLine(to: stroke.points[i])
        }
        
        // ツールに応じた描画スタイルを適用
        let strokeStyle = StrokeStyle(
            lineWidth: stroke.lineWidth,
            lineCap: .round,
            lineJoin: .round
        )
        
        switch stroke.tool {
        case .pen:
            context.stroke(
                path,
                with: .color(stroke.color),
                style: strokeStyle
            )
        case .eraser:
            // 消しゴムは背景色で描画
            context.stroke(
                path,
                with: .color(.white),
                style: strokeStyle
            )
        case .highlighter:
            // 蛍光ペンは透明度を調整
            context.stroke(
                path,
                with: .color(stroke.color.opacity(stroke.opacity)),
                style: strokeStyle
            )
        }
    }
    
    // MARK: - Gesture
    
    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if viewModel.currentStroke == nil {
                    viewModel.startDrawing(at: value.location)
                } else {
                    viewModel.addPoint(value.location)
                }
            }
            .onEnded { _ in
                viewModel.finishDrawing()
            }
    }
}