//
//  DrawingModel.swift
//  AsaDrawingPad
//  
//  Created on 2025/06/29
//

import SwiftUI

struct Line {
    var points: [CGPoint] = []
    var color: Color = .black
    var lineWidth: CGFloat = 3.0
}

@Observable
class DrawingModel {
    var lines: [Line] = []
    var currentLine = Line()
    var selectedColor: Color = Color("AsaCoffeeBrown")
    var lineWidth: CGFloat = 3.0
    
    func startDrawing(at point: CGPoint) {
        currentLine = Line(points: [point], color: selectedColor, lineWidth: lineWidth)
    }
    
    func addPoint(_ point: CGPoint) {
        currentLine.points.append(point)
    }
    
    func finishDrawing() {
        if !currentLine.points.isEmpty {
            lines.append(currentLine)
            currentLine = Line()
        }
    }
    
    func clearCanvas() {
        lines.removeAll()
        currentLine = Line()
    }
    
    func undoLastLine() {
        if !lines.isEmpty {
            lines.removeLast()
        }
    }
}