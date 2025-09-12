//
//  DrawingTool.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

// MARK: - Drawing Tool

enum DrawingTool: String, CaseIterable {
    case pen = "ペン"
    case eraser = "消しゴム"
    case highlighter = "蛍光ペン"
    
    var iconName: String {
        switch self {
        case .pen:
            return "pencil.tip"
        case .eraser:
            return "eraser"
        case .highlighter:
            return "highlighter"
        }
    }
    
    var defaultOpacity: Double {
        switch self {
        case .pen:
            return 1.0
        case .eraser:
            return 1.0
        case .highlighter:
            return 0.5
        }
    }
}