//
//  CanvasView.swift
//  AsaDrawingPad
//  
//  Created on 2025/06/29
//

import SwiftUI

struct CanvasView: View {
    @Bindable var drawingModel: DrawingModel
    
    var body: some View {
        Canvas { context, size in
            // 既存の線を描画
            for line in drawingModel.lines {
                if line.points.count > 1 {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(
                        path,
                        with: .color(line.color),
                        style: StrokeStyle(
                            lineWidth: line.lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
            
            // 現在描画中の線
            if drawingModel.currentLine.points.count > 1 {
                var path = Path()
                path.addLines(drawingModel.currentLine.points)
                context.stroke(
                    path,
                    with: .color(drawingModel.currentLine.color),
                    style: StrokeStyle(
                        lineWidth: drawingModel.currentLine.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if drawingModel.currentLine.points.isEmpty {
                        drawingModel.startDrawing(at: value.location)
                    } else {
                        drawingModel.addPoint(value.location)
                    }
                }
                .onEnded { _ in
                    drawingModel.finishDrawing()
                }
        )
    }
}