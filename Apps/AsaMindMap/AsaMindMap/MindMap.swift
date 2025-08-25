import Foundation
import SwiftUI

// MARK: - MindMap Model

struct MindMap: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var nodes: [MindMapNode]
    var connections: [MindMapConnection]
    let createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initialization
    
    init(title: String, nodes: [MindMapNode] = [], connections: [MindMapConnection] = []) {
        self.title = title
        self.nodes = nodes
        self.connections = connections
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Node Management
    
    mutating func addNode(_ node: MindMapNode) {
        nodes.append(node)
        updateModificationTime()
    }
    
    mutating func removeNode(withId nodeId: UUID) {
        nodes.removeAll { $0.id == nodeId }
        connections.removeAll { $0.isConnectedTo(nodeId: nodeId) }
        updateModificationTime()
    }
    
    mutating func updateNode(withId nodeId: UUID, _ updateClosure: (inout MindMapNode) -> Void) {
        if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
            updateClosure(&nodes[index])
            updateModificationTime()
        }
    }
    
    func getNode(withId nodeId: UUID) -> MindMapNode? {
        nodes.first { $0.id == nodeId }
    }
    
    // MARK: - Connection Management
    
    mutating func addConnection(_ connection: MindMapConnection) {
        if !connections.contains(where: { 
            ($0.fromNodeId == connection.fromNodeId && $0.toNodeId == connection.toNodeId) ||
            ($0.fromNodeId == connection.toNodeId && $0.toNodeId == connection.fromNodeId)
        }) {
            connections.append(connection)
            updateModificationTime()
        }
    }
    
    mutating func removeConnection(withId connectionId: UUID) {
        connections.removeAll { $0.id == connectionId }
        updateModificationTime()
    }
    
    mutating func connectNodes(fromId: UUID, toId: UUID) {
        let connection = MindMapConnection.connect(fromId: fromId, toId: toId)
        addConnection(connection)
    }
    
    func getConnectedNodes(to nodeId: UUID) -> [MindMapNode] {
        let connectedIds = connections.compactMap { connection in
            connection.getOtherNodeId(currentNodeId: nodeId)
        }
        return nodes.filter { connectedIds.contains($0.id) }
    }
    
    // MARK: - Utility Methods
    
    private mutating func updateModificationTime() {
        modifiedAt = Date()
    }
    
    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        updateModificationTime()
    }
    
    mutating func clearAll() {
        nodes.removeAll()
        connections.removeAll()
        updateModificationTime()
    }
    
    // MARK: - Computed Properties
    
    var nodeCount: Int {
        nodes.count
    }
    
    var connectionCount: Int {
        connections.count
    }
    
    var isEmpty: Bool {
        nodes.isEmpty && connections.isEmpty
    }
    
    var formattedCreatedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var formattedModifiedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modifiedAt)
    }
    
    // MARK: - Static Factory Methods
    
    static func createEmpty(title: String) -> MindMap {
        MindMap(title: title)
    }
    
    static func createWithCentralNode(title: String, centralNodeText: String) -> MindMap {
        let centralNode = MindMapNode.createCentralNode(text: centralNodeText)
        return MindMap(title: title, nodes: [centralNode])
    }
}

// MARK: - MindMap Extensions

extension MindMap {
    // MARK: - Sample Data for Preview
    
    static let sampleMindMap: MindMap = {
        let centralNode = MindMapNode.createCentralNode(text: "朝活アイデア")
        
        let childNodes = [
            MindMapNode(text: "SwiftUI学習", position: CGPoint(x: 100, y: 200)),
            MindMapNode(text: "健康管理", position: CGPoint(x: 300, y: 200)),
            MindMapNode(text: "読書", position: CGPoint(x: 100, y: 400)),
            MindMapNode(text: "運動", position: CGPoint(x: 300, y: 400))
        ]
        
        let connections = [
            MindMapConnection.connect(fromId: centralNode.id, toId: childNodes[0].id),
            MindMapConnection.connect(fromId: centralNode.id, toId: childNodes[1].id),
            MindMapConnection.connect(fromId: centralNode.id, toId: childNodes[2].id),
            MindMapConnection.connect(fromId: centralNode.id, toId: childNodes[3].id)
        ]
        
        return MindMap(
            title: "サンプルマインドマップ",
            nodes: [centralNode] + childNodes,
            connections: connections
        )
    }()
}