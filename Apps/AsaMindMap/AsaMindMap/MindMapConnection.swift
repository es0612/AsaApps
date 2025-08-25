import Foundation
import SwiftUI

// MARK: - MindMapConnection Model

struct MindMapConnection: Identifiable, Codable, Equatable {
    let id = UUID()
    let fromNodeId: UUID
    let toNodeId: UUID
    var lineStyle: LineStyle
    var createdAt: Date
    
    // MARK: - Initialization
    
    init(fromNodeId: UUID, toNodeId: UUID, lineStyle: LineStyle = .solid) {
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.lineStyle = lineStyle
        self.createdAt = Date()
    }
    
    // MARK: - Helper Methods
    
    func isConnectedTo(nodeId: UUID) -> Bool {
        fromNodeId == nodeId || toNodeId == nodeId
    }
    
    func getOtherNodeId(currentNodeId: UUID) -> UUID? {
        if fromNodeId == currentNodeId {
            return toNodeId
        } else if toNodeId == currentNodeId {
            return fromNodeId
        }
        return nil
    }
    
    // MARK: - Static Factory Methods
    
    static func connect(from: MindMapNode, to: MindMapNode) -> MindMapConnection {
        MindMapConnection(fromNodeId: from.id, toNodeId: to.id)
    }
    
    static func connect(fromId: UUID, toId: UUID, style: LineStyle = .solid) -> MindMapConnection {
        MindMapConnection(fromNodeId: fromId, toNodeId: toId, lineStyle: style)
    }
}

// MARK: - LineStyle Enum

enum LineStyle: String, CaseIterable, Codable {
    case solid = "solid"
    case dashed = "dashed"
    case dotted = "dotted"
    
    var displayName: String {
        switch self {
        case .solid:
            return "実線"
        case .dashed:
            return "破線"
        case .dotted:
            return "点線"
        }
    }
    
    var strokeStyle: StrokeStyle {
        switch self {
        case .solid:
            return StrokeStyle(lineWidth: 2, lineCap: .round)
        case .dashed:
            return StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 4])
        case .dotted:
            return StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4])
        }
    }
}

// MARK: - MindMapConnection Extensions

extension MindMapConnection {
    var formattedCreatedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Sample Data for Preview
    
    static let sampleConnections: [MindMapConnection] = [
        MindMapConnection(fromNodeId: UUID(), toNodeId: UUID()),
        MindMapConnection(fromNodeId: UUID(), toNodeId: UUID(), lineStyle: .dashed),
        MindMapConnection(fromNodeId: UUID(), toNodeId: UUID(), lineStyle: .dotted)
    ]
}