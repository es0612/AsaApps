//
//  DrawingLayer.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

// MARK: - Drawing Layer

struct DrawingLayer: Identifiable {
    let id = UUID()
    var name: String
    var strokes: [DrawingStroke] = []
    var isVisible: Bool = true
    var opacity: Double = 1.0
    var isLocked: Bool = false
    
    init(name: String = "新規レイヤー") {
        self.name = name
    }
    
    // レイヤーが空かどうか
    var isEmpty: Bool {
        strokes.isEmpty
    }
    
    // レイヤーの描画内容をクリア
    mutating func clear() {
        strokes.removeAll()
    }
    
    // 最後のストロークを削除（アンドゥ機能）
    mutating func removeLastStroke() {
        if !strokes.isEmpty {
            strokes.removeLast()
        }
    }
}