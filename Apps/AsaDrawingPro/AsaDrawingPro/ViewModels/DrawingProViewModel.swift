//
//  DrawingProViewModel.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

// MARK: - Drawing Pro ViewModel

@Observable
final class DrawingProViewModel {
    // MARK: - Properties
    
    var layers: [DrawingLayer] = []
    var selectedLayerID: UUID?
    var currentStroke: DrawingStroke?
    
    // 描画ツール設定
    var selectedTool: DrawingTool = .pen
    var selectedColor: Color = .asaCoffeeBrown
    var brushSize: CGFloat = 3.0
    
    // UIの状態
    var isLayerPanelVisible: Bool = true
    var isToolPanelVisible: Bool = true
    
    // MARK: - Computed Properties
    
    var selectedLayer: DrawingLayer? {
        get {
            guard let id = selectedLayerID else { return nil }
            return layers.first { $0.id == id }
        }
        set {
            if let newLayer = newValue,
               let index = layers.firstIndex(where: { $0.id == newLayer.id }) {
                layers[index] = newLayer
            }
        }
    }
    
    var selectedLayerIndex: Int? {
        guard let id = selectedLayerID else { return nil }
        return layers.firstIndex { $0.id == id }
    }
    
    var canAddLayer: Bool {
        layers.count < 10  // 最大10レイヤーまで
    }
    
    // MARK: - Initialization
    
    init() {
        // 初期レイヤーを作成
        let initialLayer = DrawingLayer(name: "レイヤー1")
        layers.append(initialLayer)
        selectedLayerID = initialLayer.id
    }
    
    // MARK: - Layer Management
    
    func addLayer() {
        guard canAddLayer else { return }
        
        let layerNumber = layers.count + 1
        let newLayer = DrawingLayer(name: "レイヤー\(layerNumber)")
        layers.insert(newLayer, at: 0)  // 最上位に追加
        selectedLayerID = newLayer.id
    }
    
    func deleteLayer(_ id: UUID) {
        guard layers.count > 1 else { return }  // 最低1つのレイヤーは必要
        
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers.remove(at: index)
            
            // 削除したレイヤーが選択中だった場合、別のレイヤーを選択
            if selectedLayerID == id {
                selectedLayerID = layers.first?.id
            }
        }
    }
    
    func toggleLayerVisibility(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isVisible.toggle()
        }
    }
    
    func toggleLayerLock(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isLocked.toggle()
        }
    }
    
    func updateLayerOpacity(_ id: UUID, opacity: Double) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].opacity = opacity
        }
    }
    
    func renameLayer(_ id: UUID, newName: String) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].name = newName
        }
    }
    
    func reorderLayers(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
    }
    
    func mergeLayerDown(_ id: UUID) {
        guard let upperIndex = layers.firstIndex(where: { $0.id == id }),
              upperIndex < layers.count - 1 else { return }
        
        let lowerIndex = upperIndex + 1
        layers[lowerIndex].strokes.append(contentsOf: layers[upperIndex].strokes)
        layers.remove(at: upperIndex)
    }
    
    // MARK: - Drawing Methods
    
    func startDrawing(at point: CGPoint) {
        guard let selectedLayer = selectedLayer,
              !selectedLayer.isLocked else { return }
        
        currentStroke = DrawingStroke(
            points: [point],
            color: selectedColor,
            lineWidth: brushSize,
            tool: selectedTool
        )
    }
    
    func addPoint(_ point: CGPoint) {
        guard selectedLayer != nil,
              !(selectedLayer?.isLocked ?? false) else { return }
        
        currentStroke?.points.append(point)
    }
    
    func finishDrawing() {
        guard let stroke = currentStroke,
              let index = selectedLayerIndex,
              !stroke.points.isEmpty else { return }
        
        layers[index].strokes.append(stroke)
        currentStroke = nil
    }
    
    // MARK: - Undo/Redo/Clear
    
    func undo() {
        guard let index = selectedLayerIndex else { return }
        layers[index].removeLastStroke()
    }
    
    func clearCurrentLayer() {
        guard let index = selectedLayerIndex else { return }
        layers[index].clear()
    }
    
    func clearAllLayers() {
        for index in layers.indices {
            layers[index].clear()
        }
    }
    
    func clearLayer(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].clear()
        }
    }
}