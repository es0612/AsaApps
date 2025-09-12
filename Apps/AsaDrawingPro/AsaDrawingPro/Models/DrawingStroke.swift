//
//  DrawingStroke.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

// MARK: - Drawing Stroke

struct DrawingStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var tool: DrawingTool
    var opacity: Double
    
    init(
        points: [CGPoint] = [],
        color: Color = .black,
        lineWidth: CGFloat = 3.0,
        tool: DrawingTool = .pen
    ) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.tool = tool
        self.opacity = tool.defaultOpacity
    }
    
    // 描画パスを生成
    var path: Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        return path
    }
}