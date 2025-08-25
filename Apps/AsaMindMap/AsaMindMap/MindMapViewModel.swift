import Foundation
import SwiftUI
import Observation

// MARK: - MindMapViewModel

@Observable
class MindMapViewModel {
    
    // MARK: - Properties
    
    private(set) var mindMaps: [MindMap] = []
    private(set) var currentMindMap: MindMap?
    var isEditing = false
    var selectedNodeId: UUID?
    var connectingFromNodeId: UUID?
    var canvasOffset = CGSize.zero
    var canvasScale: CGFloat = 1.0
    
    // 新規ノード作成時のテキスト
    var newNodeText = ""
    
    // パン操作の状態
    var isPanGestureActive = false
    
    private let mindMapsKey = "AsaMindMap_MindMaps"
    private let currentMindMapKey = "AsaMindMap_CurrentMindMapId"
    
    // MARK: - Initialization
    
    init() {
        loadMindMaps()
        
        // 初回起動時にサンプルマインドマップを作成
        if mindMaps.isEmpty {
            createSampleMindMap()
        }
        
        // 前回開いていたマインドマップを復元
        loadCurrentMindMap()
    }
    
    // MARK: - MindMap Management
    
    func createNewMindMap(title: String) {
        let newMindMap = MindMap.createWithCentralNode(title: title, centralNodeText: title)
        mindMaps.append(newMindMap)
        currentMindMap = newMindMap
        saveMindMaps()
        saveCurrentMindMapId()
    }
    
    func selectMindMap(_ mindMap: MindMap) {
        currentMindMap = mindMap
        resetCanvasTransform()
        saveCurrentMindMapId()
    }
    
    func deleteMindMap(withId mindMapId: UUID) {
        mindMaps.removeAll { $0.id == mindMapId }
        if currentMindMap?.id == mindMapId {
            currentMindMap = mindMaps.first
        }
        saveMindMaps()
        saveCurrentMindMapId()
    }
    
    func updateCurrentMindMapTitle(_ newTitle: String) {
        guard var mindMap = currentMindMap else { return }
        mindMap.updateTitle(newTitle)
        updateCurrentMindMap(mindMap)
    }
    
    // MARK: - Node Management
    
    func addNode(text: String, position: CGPoint) {
        guard var mindMap = currentMindMap else { return }
        let adjustedPosition = adjustPositionForCanvas(position)
        let newNode = MindMapNode.createNode(text: text, position: adjustedPosition)
        mindMap.addNode(newNode)
        updateCurrentMindMap(mindMap)
    }
    
    func updateNodeText(nodeId: UUID, text: String) {
        guard var mindMap = currentMindMap else { return }
        mindMap.updateNode(withId: nodeId) { node in
            node.updateText(text)
        }
        updateCurrentMindMap(mindMap)
    }
    
    func updateNodePosition(nodeId: UUID, position: CGPoint) {
        guard var mindMap = currentMindMap else { return }
        let adjustedPosition = adjustPositionForCanvas(position)
        mindMap.updateNode(withId: nodeId) { node in
            node.updatePosition(adjustedPosition)
        }
        updateCurrentMindMap(mindMap)
    }
    
    func updateNodeColor(nodeId: UUID, color: NodeColor) {
        guard var mindMap = currentMindMap else { return }
        mindMap.updateNode(withId: nodeId) { node in
            node.updateColor(color)
        }
        updateCurrentMindMap(mindMap)
    }
    
    func deleteNode(withId nodeId: UUID) {
        guard var mindMap = currentMindMap else { return }
        mindMap.removeNode(withId: nodeId)
        
        if selectedNodeId == nodeId {
            selectedNodeId = nil
        }
        if connectingFromNodeId == nodeId {
            connectingFromNodeId = nil
        }
        
        updateCurrentMindMap(mindMap)
    }
    
    func toggleNodeEditing(nodeId: UUID) {
        guard var mindMap = currentMindMap else { return }
        mindMap.updateNode(withId: nodeId) { node in
            node.toggleEditing()
        }
        updateCurrentMindMap(mindMap)
    }
    
    // MARK: - Connection Management
    
    func startConnecting(fromNodeId: UUID) {
        connectingFromNodeId = fromNodeId
    }
    
    func completeConnection(toNodeId: UUID) {
        guard let fromNodeId = connectingFromNodeId,
              var mindMap = currentMindMap,
              fromNodeId != toNodeId else {
            connectingFromNodeId = nil
            return
        }
        
        mindMap.connectNodes(fromId: fromNodeId, toId: toNodeId)
        updateCurrentMindMap(mindMap)
        connectingFromNodeId = nil
    }
    
    func cancelConnection() {
        connectingFromNodeId = nil
    }
    
    func deleteConnection(withId connectionId: UUID) {
        guard var mindMap = currentMindMap else { return }
        mindMap.removeConnection(withId: connectionId)
        updateCurrentMindMap(mindMap)
    }
    
    // MARK: - Canvas Management
    
    func updateCanvasTransform(offset: CGSize, scale: CGFloat) {
        canvasOffset = offset
        canvasScale = max(0.5, min(3.0, scale)) // スケール制限
    }
    
    func resetCanvasTransform() {
        canvasOffset = .zero
        canvasScale = 1.0
    }
    
    private func adjustPositionForCanvas(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: (position.x - canvasOffset.width) / canvasScale,
            y: (position.y - canvasOffset.height) / canvasScale
        )
    }
    
    func getDisplayPosition(for position: CGPoint) -> CGPoint {
        CGPoint(
            x: position.x * canvasScale + canvasOffset.width,
            y: position.y * canvasScale + canvasOffset.height
        )
    }
    
    // MARK: - Helper Methods
    
    private func updateCurrentMindMap(_ mindMap: MindMap) {
        currentMindMap = mindMap
        
        // mindMaps配列も更新
        if let index = mindMaps.firstIndex(where: { $0.id == mindMap.id }) {
            mindMaps[index] = mindMap
        }
        
        saveMindMaps()
    }
    
    func clearCurrentMindMap() {
        guard var mindMap = currentMindMap else { return }
        mindMap.clearAll()
        updateCurrentMindMap(mindMap)
        resetCanvasTransform()
    }
    
    // MARK: - Computed Properties
    
    var currentNodes: [MindMapNode] {
        currentMindMap?.nodes ?? []
    }
    
    var currentConnections: [MindMapConnection] {
        currentMindMap?.connections ?? []
    }
    
    var isConnecting: Bool {
        connectingFromNodeId != nil
    }
    
    var mindMapCount: Int {
        mindMaps.count
    }
    
    var currentNodeCount: Int {
        currentMindMap?.nodeCount ?? 0
    }
    
    var currentConnectionCount: Int {
        currentMindMap?.connectionCount ?? 0
    }
    
    // MARK: - Persistence
    
    private func saveMindMaps() {
        do {
            let data = try JSONEncoder().encode(mindMaps)
            UserDefaults.standard.set(data, forKey: mindMapsKey)
        } catch {
            print("マインドマップの保存に失敗しました: \(error)")
        }
    }
    
    private func loadMindMaps() {
        guard let data = UserDefaults.standard.data(forKey: mindMapsKey) else { return }
        
        do {
            mindMaps = try JSONDecoder().decode([MindMap].self, from: data)
        } catch {
            print("マインドマップの読み込みに失敗しました: \(error)")
            mindMaps = []
        }
    }
    
    private func saveCurrentMindMapId() {
        if let currentId = currentMindMap?.id.uuidString {
            UserDefaults.standard.set(currentId, forKey: currentMindMapKey)
        }
    }
    
    private func loadCurrentMindMap() {
        guard let currentIdString = UserDefaults.standard.string(forKey: currentMindMapKey),
              let currentId = UUID(uuidString: currentIdString) else {
            currentMindMap = mindMaps.first
            return
        }
        
        currentMindMap = mindMaps.first { $0.id == currentId } ?? mindMaps.first
    }
    
    private func createSampleMindMap() {
        let sampleMindMap = MindMap.sampleMindMap
        mindMaps.append(sampleMindMap)
        currentMindMap = sampleMindMap
        saveMindMaps()
        saveCurrentMindMapId()
    }
}